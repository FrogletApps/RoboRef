# RoboRef Privacy Policy

**Last Updated:** September 2026

RoboRef ("we", "our", or "the app") is an independent, offline-first match anomaly log and referee companion designed for Head Referees and tournament staff at robotics competitions. We believe your data belongs to you, and we design our software with privacy, minimal data collection, and local-first principles.

---

### 1. Offline-First by Design
* **Local Storage:** RoboRef operates offline-first. All competition data—including match schedules, team incident notes, anomaly logs, and referee entries—is stored locally on your device in an encrypted local database.
* **No Account Required:** You do not need to register, create an account, or log in with an email address or password to use RoboRef.
* **No Cloud Transmission in Offline Mode:** If you do not explicitly enable event synchronization, your notes and incident logs never leave your physical device.

---

### 2. Data Synchronization (When Enabled)
RoboRef offers optional multi-device peer synchronization to allow tournament referees to coordinate incident notes during an active event:

* **Local Venue LAN Mode (`roboref.local`):**  
  When connected to a tournament's local field server (such as a venue Raspberry Pi), data synchronizes entirely within the local venue network. No event data or notes transit over the public internet.
* **Cloud Sync Mode (`roboref.app`):**  
  When cloud synchronization is selected, event anomaly logs and field notes are transmitted using industry-standard TLS encryption (HTTPS/WSS) and stored in secured database instances.
* **Access Isolation:** Data synchronized for a specific event is segregated by event code and instance tokens; only participants actively joined to that event instance can send or receive that event's notes.

---

### 3. What We Do NOT Collect
* **No Personal Identifiable Information (PII):** We do not collect names, email addresses, phone numbers, or physical addresses. An optional referee display name or initials can be entered strictly for attribution on the field; this name is stored locally and shared only with referees on the same event sync session.
* **No Advertising or Tracking:** RoboRef contains zero third-party advertising SDKs, ad trackers, telemetry beacons, or commercial data brokers.
* **No Sensitive Device Permissions:** RoboRef does not access your location, camera, microphone, contacts, photo library, or SMS. It requests only standard network access (`INTERNET`) to fetch public match schedules and provide optional peer synchronization.

---

### 4. Data Retention & Deletion
* **On Your Device:** You retain complete control over your local data. You can delete individual incident entries, clear entire event workspaces, or erase all stored data at any time by clearing the app's storage or uninstalling the application.
* **On Sync Servers:** Synced event records on RoboRef cloud servers or local venue servers are temporary operational logs created to facilitate the tournament and may be periodically purged after the event concludes.

---

### 5. Third-Party Services & Public APIs
* **Competition APIs:** When importing tournament schedules and team lists, RoboRef queries public competition endpoints (such as RobotEvents / VEX Events APIs) to populate match and team numbers. These requests do not transmit personal user data.
* **Infrastructure Providers:** Cloud synchronization is hosted on secure RoboRef cloud infrastructure, adhering to rigorous data security and encryption-at-rest standards.

---

### 6. Children’s Privacy
RoboRef is designed as an operational tool for tournament Head Referees, Event Partners, and adult competition staff (intended for users aged 13 and older). We do not knowingly collect or solicit personal information from children under the age of 13.

---

### 7. Trademark Disclaimer
RoboRef is an independent tool and is not affiliated with, sponsored by, or endorsed by VEX Robotics, Inc. or the Global Robotics & Science Foundation. VEX is a registered trademark of Innovation First International, Inc.

---

### 8. Contact & Inquiries
If you have questions, concerns, or requests regarding this Privacy Policy or your data, please contact the developer via email at:  
[dev@roboref.app](mailto:dev@roboref.app)
