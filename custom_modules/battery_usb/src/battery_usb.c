#include <stdio.h>

#include <zephyr/device.h>
#include <zephyr/drivers/uart.h>
#include <zephyr/init.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/atomic.h>
#include <zephyr/usb/usb_device.h>

#include <zmk/event_manager.h>
#include <zmk/events/battery_state_changed.h>
#include <zmk/split/central.h>
#include <zmk/usb.h>

static const struct device *const serial = DEVICE_DT_GET(DT_NODELABEL(battery_usb_uart));

// Store percentage + 1 so zero-initialized slots mean "not received yet".
static atomic_t levels[ZMK_SPLIT_BLE_PERIPHERAL_COUNT];

static int battery_listener(const zmk_event_t *eh) {
    const struct zmk_peripheral_battery_state_changed *ev =
        as_zmk_peripheral_battery_state_changed(eh);

    if (ev && ev->source < ARRAY_SIZE(levels) && ev->state_of_charge <= 100) {
        // Upstream also sends 0 on disconnect; it cannot be distinguished from 0% here.
        atomic_set(&levels[ev->source], ev->state_of_charge + 1);
    }
    return ZMK_EV_EVENT_BUBBLE;
}

ZMK_LISTENER(battery_usb, battery_listener);
ZMK_SUBSCRIPTION(battery_usb, zmk_peripheral_battery_state_changed);

static void write_serial(const char *text) {
    // The pinned Zephyr CDC ACM driver's poll_out queues bytes without blocking.
    // On overflow it drops old bytes. Leading newlines let readers resynchronize.
    for (const char *p = text; *p; p++) {
        uart_poll_out(serial, *p);
    }
}

static void report_batteries(void) {
    write_serial("\n{\"peripherals\":[");
    for (size_t i = 0; i < ARRAY_SIZE(levels); i++) {
        int level = atomic_get(&levels[i]) - 1;
        char percent[5] = "null";
        char entry[48];

        if (level >= 0 && level <= 100) {
            snprintf(percent, sizeof(percent), "%d", level);
        }
        snprintf(entry, sizeof(entry), "%s{\"slot\":%u,\"percent\":%s}", i ? "," : "",
                 (unsigned int)i, percent);
        write_serial(entry);
    }
    write_serial("]}\n");
}

static void report_work_handler(struct k_work *work);
K_WORK_DELAYABLE_DEFINE(report_work, report_work_handler);

static void report_work_handler(struct k_work *work) {
    static bool was_open;
    static int64_t next_report;
    uint32_t dtr = 0;
    enum usb_dc_status_code status = zmk_usb_get_status();
    bool open = zmk_usb_is_hid_ready() && status != USB_DC_SUSPEND &&
                uart_line_ctrl_get(serial, UART_LINE_CTRL_DTR, &dtr) == 0 && dtr;
    int64_t now = k_uptime_get();

    if (open && (!was_open || now >= next_report)) {
        report_batteries();
        next_report = now + 5000;
    }
    was_open = open;
    k_work_reschedule(&report_work, K_SECONDS(1));
}

static int battery_usb_init(void) {
    if (!device_is_ready(serial)) {
        return -ENODEV;
    }
    k_work_reschedule(&report_work, K_SECONDS(1));
    return 0;
}

SYS_INIT(battery_usb_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
