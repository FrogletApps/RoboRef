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

If you enter image data into RoboRef, this data is stored locally on your device unless you enable the sharing functionality for that event. When sharing is enabled, attached images are securely uploaded to Cloudflare R2 Object Storage to synchronize across event referees.

Images stored in Cloudflare R2 are **not** publicly accessible. Privacy and access control are strictly enforced: technical guardrails verify cryptographically signed user credentials and event invitation tokens, ensuring that clients can only access image data for an event if both the uploader and the requesting device are active participants on the same sharing instance for that event.

To minimize data retention and protect privacy, images uploaded to Cloudflare R2 are automatically and permanently deleted after **30 days**.

The RoboRef sync mechanism and image storage are built on Cloudflare Workers and Cloudflare R2 Object Storage. All data is encrypted at rest using AES encryption.

### How We Use Your Data

RoboRef is not currently monetized. Any data uploaded to the synchronization
mechanism is used to facilitate the service. We do not sell data to third
parties.

Unless in exceptional circumstances, RoboRef will not disclose data you
upload to the synchronization service to third parties without your consent.

The authors of RoboRef make no guarantees about the longevity of the data
stored in the synchronization mechanism. RoboRef is provided "as-is", and
the authors disclaim all liability for using it at your events.
