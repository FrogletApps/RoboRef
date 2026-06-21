## RoboRef Privacy Policy

RoboRef is a tool designed to help Head Referees in robotics competitions
quickly and efficiently record data in the anomaly log. We treat the
responsibility to take care of this data seriously.

> RoboRef is designed to work offline-first. If you do not enable the sharing
> mechanism, the contents of incidents or images in the anomaly log does not leave
> your device.

### What We Collect

You do not need to register an account to use RoboRef. 

RoboRef collects basic crash report and anonymized user traffic data.

If you use the sharing functionality to synchronize anomaly log between multiple
devices, the contents of the anomaly log is stored on our servers. This data may
be accessed by the developers of RoboRef for quality assurance or technical
support purposes.

If you enter image data into RoboRef, this data is stored on your local
device unless you utilize sharing functionality for that event. To enable
multiple devices to share images, your device will upload images attached to any
entries for the given event when you enable sharing. Images are _not_ publicly
accessible, even if you know the URL. Technical guardrails are in place to
prevent clients from accessing image data for an event unless both the creator
device and the requesting device are currently on the same sharing instance for
that event.

The RoboRef sync mechanism is currently built using Cloudflare Workers. All
data is encrypted at rest using AES encryption.

### How We Use Your Data

RoboRef is not currently monetized. Any data uploaded to the synchronization
mechanism is used to facilitate the service. We do not sell data to third
parties.

Unless in exceptional circumstances, RoboRef will not disclose data you
upload to the synchronization service to third parties without your consent.

The authors of RoboRef make no guarantees about the longevity of the data
stored in the synchronization mechanism. RoboRef is provided "as-is", and
the authors disclaim all liability for using it at your events.
