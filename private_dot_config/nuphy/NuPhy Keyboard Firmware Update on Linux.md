# NuPhy Keyboard Firmware Update on Linux - Complete Troubleshooting Guide

## Problem Description

When attempting to update firmware on a NuPhy keyboard (Air 75 v3 or similar models) using the official web updater at nuphy.io on Linux (Ubuntu/Debian-based distributions), you may encounter:

1. **Connection Issues**: The web updater cannot detect or connect to the keyboard
2. **Failed Firmware Update**: The update process fails midway, leaving the keyboard stuck in "Upgrade Mode"
3. **Bricked Keyboard**: Keyboard becomes non-functional, only showing up as "NuPhy Air75 V3 Upgrader" in `lsusb`

## Understanding the Issue

The root cause is **Linux USB permissions**. By default, Linux restricts access to USB HID (Human Interface Device) raw devices for security reasons. Web browsers cannot access these devices without proper permissions, causing the firmware updater to fail.

## Solution Steps

### Step 1: Quick Fix for Immediate Access (Temporary)

For immediate access to update firmware, grant permissions to hidraw devices:

```bash
# This is temporary and resets on reboot
sudo chmod a+rw /dev/hidraw*
```

**Note**: This is a temporary fix that:

- Only works until the next reboot
- Must be run each time you need to update firmware
- Is less secure as it grants all users access to all HID devices

### Step 2: Permanent Solution with udev Rules

Create permanent USB permission rules for NuPhy devices:

1. **Create a new udev rules file:**

```bash
sudo nano /etc/udev/rules.d/50-nuphy.rules
```

1. **Add the following content:**

```
# NuPhy keyboards
SUBSYSTEM=="usb", ATTR{idVendor}=="19f5", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="19f5", MODE="0666", GROUP="plugdev"
```

1. **Save the file** (Ctrl+O, Enter, Ctrl+X in nano)
2. **Reload udev rules:**

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

1. **Add your user to the plugdev group:**

```bash
sudo usermod -a -G plugdev $USER
```

1. **Apply group changes** (choose one):

```bash
# Option A: Log out and log back in
# Option B: Reboot the system
sudo reboot
# Option C: Apply in current session (may not work for all applications)
newgrp plugdev
```

### Step 3: Updating the Firmware

After setting up permissions:

1. **Open Chrome or Chromium browser**
   - Firefox may have compatibility issues with WebUSB
   - For best results use: `chromium --enable-experimental-web-platform-features`
2. **Navigate to nuphy.io**
3. **Connect your keyboard via USB-C cable**
   - Ensure battery is charged above 50%
   - Use a data-capable USB cable (not charge-only)
4. **Follow the update process:**
   - Select your keyboard model
   - Click "Connect"
   - When prompted, select "NuPhy Air75 V3" or "NuPhy Air75 V3 Upgrader" from the device list
   - Click "Update Firmware"
   - DO NOT disconnect until complete

## Diagnostic Commands

### Check USB Device Detection

```bash
# List all USB devices
lsusb

# Watch USB devices in real-time
watch -n 1 lsusb

# Check kernel messages
sudo dmesg | tail -20

# Check HID raw devices
ls -la /dev/hidraw*
```

### Monitor During Update Attempt

```bash
# Terminal 1: Watch kernel messages
sudo dmesg -w

# Terminal 2: Monitor USB devices
watch -n 1 lsusb
```

### Verify Permissions

```bash
# Check device permissions
ls -l /dev/hidraw*

# Check your groups
groups

# Check udev rules loaded
udevadm info -a -n /dev/hidraw0
```

## Troubleshooting Common Issues

### Issue: Browser Can't Find Device

**Solution**:

- Ensure udev rules are loaded: `sudo udevadm trigger`
- Try the temporary chmod fix first: `sudo chmod a+rw /dev/hidraw*`
- Use Chrome/Chromium, not Firefox

### Issue: Update Fails Midway

**Solution**:

- Check battery level (needs >50%)
- Try different USB port (USB 2.0 preferred)
- Disable antivirus temporarily
- Clear browser cache for nuphy.io

### Issue: Device Not Recognized

**Solution**:

- Try different USB cable (must be data-capable)
- Check cable connection at both ends
- Try USB 2.0 port instead of USB 3.0
- Boot into BIOS/UEFI to check if keyboard works there

### Issue: Permission Denied Errors

**Solution**:

- Verify udev rules syntax is correct
- Ensure you're in plugdev group: `groups | grep plugdev`
- Reboot after adding to group (logout may not be sufficient)

## Additional Notes

### Supported Browsers

- ✅ Chrome/Chromium (Recommended)
- ⚠️ Firefox (May have WebUSB issues)

### NuPhy Keyboard Shortcuts

- **Bluetooth Device 1/2/3**: Fn + 1/2/3
- **2.4GHz Mode**: Fn + 4
- **Wired Mode**: Automatic when USB connected

## Final Checklist

Before attempting firmware update:

- [ ] Battery charged >50%
- [ ] Using data-capable USB cable
- [ ] udev rules created and loaded
- [ ] User added to plugdev group
- [ ] System rebooted after group change
- [ ] Using Chrome/Chromium browser
- [ ] Keyboard configuration backed up

## Author Notes

*This guide was created after successfully recovering a NuPhy Air 75 v3 stuck in upgrade mode on Ubuntu Linux. The critical missing piece in most documentation is the USB permission configuration required for Linux systems. The temporary `chmod` command provides immediate relief while the udev rules offer a permanent solution.*

*Last updated: 2025*