#!/usr/bin/env python3
"""
Apply cloud configuration + supervision for GIGI using pymobiledevice3 (USB).

Maps to library APIs:
  - MobileActivationService.activate() if device is Unactivated
  - MobileConfigService.supervise(organization, keybag)  -> IsSupervised, OrganizationName, SkipSetup, ...
  - MobileConfigService.set_cloud_configuration()        -> merge CloudConfigurationUIHierarchy (best-effort)
  - MobileConfigService.store_profile(..., Purpose.PostSetupInstallation)  # optional; Apple "post setup" profile slot

There is no literal "CloudConfig.post_setup_activation" in pymobiledevice3; PostSetupInstallation + store_profile is the
documented equivalent for storing a profile for post-setup application.

Requires: pip install pymobiledevice3 (see requirements-device.txt)
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)


async def _main_async(args: argparse.Namespace) -> int:
    from pymobiledevice3.ca import create_keybag_file
    from pymobiledevice3.exceptions import CloudConfigurationAlreadyPresentError
    from pymobiledevice3.lockdown import create_using_usbmux
    from pymobiledevice3.services.mobile_activation import MobileActivationService
    from pymobiledevice3.services.mobile_config import MobileConfigService, Purpose

    async with await create_using_usbmux(serial=args.udid) as lockdown:
        activation = MobileActivationService(lockdown)
        state = await activation.state()
        logger.info("Mobile activation state: %s", state)
        if state == "Unactivated":
            logger.info("Activating device (MobileActivationService.activate)")
            await activation.activate()

        mc = MobileConfigService(lockdown)

        try:
            if args.keybag:
                keybag_path = Path(args.keybag).resolve()
                if not keybag_path.is_file():
                    logger.error("Keybag not found: %s", keybag_path)
                    return 1
                logger.info("Supervising as organization: %s", args.organization)
                await mc.supervise(args.organization, keybag_path)
            else:
                with tempfile.TemporaryDirectory(prefix="gigi_keybag_") as tmp:
                    keybag_path = Path(tmp) / "supervisor_keybag.pem"
                    logger.info("Generating temporary keybag (ephemeral dir)")
                    create_keybag_file(keybag_path, args.organization)
                    logger.info("Supervising as organization: %s", args.organization)
                    await mc.supervise(args.organization, keybag_path)
        except CloudConfigurationAlreadyPresentError:
            logger.error(
                "Cloud configuration already present. Erase the device first "
                "(e.g. pymobiledevice3 profile erase-device) or use a freshly wiped device."
            )
            return 2

        # Best-effort: hide cloud configuration UI hierarchy (key may be ignored on some iOS builds)
        cfg = await mc.get_cloud_configuration()
        if not isinstance(cfg, dict):
            cfg = {}
        cfg["CloudConfigurationUIHierarchy"] = False
        logger.info("Merging CloudConfigurationUIHierarchy=False into cloud configuration")
        await mc.set_cloud_configuration(cfg)

        if args.store_profile:
            p = Path(args.store_profile)
            if not p.is_file():
                logger.error("--store-profile not found: %s", p)
                return 1
            logger.info("Storing profile for PostSetupInstallation: %s", p)
            await mc.store_profile(p.read_bytes(), Purpose.PostSetupInstallation)

        logger.info("Done.")
        return 0


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    parser = argparse.ArgumentParser(
        description="GIGI: supervise device + cloud config (pymobiledevice3, USB / Hello-capable states)"
    )
    parser.add_argument(
        "--organization",
        default="GIGI",
        help="Organization name shown on supervised device (default: GIGI)",
    )
    parser.add_argument("--udid", default=None, help="Device UDID (default: single connected device)")
    parser.add_argument(
        "--keybag",
        default=None,
        help="Supervisor keybag PEM (cert+key). If omitted, a temporary keybag is generated.",
    )
    parser.add_argument(
        "--store-profile",
        default=None,
        help="Optional .mobileconfig bytes to store with Purpose.PostSetupInstallation (post-setup slot)",
    )
    args = parser.parse_args()

    try:
        return asyncio.run(_main_async(args))
    except ImportError as e:
        print("Install dependencies: python3 -m pip install -r requirements-device.txt", file=sys.stderr)
        print(e, file=sys.stderr)
        return 127
    except Exception:
        logger.exception("Failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
