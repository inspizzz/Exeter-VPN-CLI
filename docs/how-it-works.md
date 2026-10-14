# How the Exeter VPN works (from a Linux point of view)

Reverse-engineered while getting it running on Fedora. The details below are what we observed in October 2026.

## Pieces

| Piece | What it is |
|---|---|
| Gateway | `remote.exeter.ac.uk` (144.173.255.40), an HPE Aruba controller |
| Client | Aruba **VIA** 4.7.6: `via-vpn-srv` (root service `via-vpn.service`), `via-cli`, `via-ui` (Qt5 GUI) |
| Web auth profile | `UoE-VIA-Auth`, the only one offered (index 1) |
| VPN profile | `UoE-VIA-Connection`, role e.g. `VIA-Student`, IKEv2 with EAP-MSCHAPv2 |
| MFA | Microsoft Entra MFA behind RADIUS: Authenticator push or phone call |
| TLS chain | `remote.exeter.ac.uk` ← Sectigo Public Server Authentication CA OV R36 ← Sectigo Root R46 ← AAA Certificate Services (Exeter's `rootca.pem`) |

## Step 1: web login + profile download (HTTPS)

```
POST https://remote.exeter.ac.uk/via/login
     opcode=login&url=/via/login&needxml=0&uid=<user>&passwd=<pw>&vap=UoE-VIA-Auth
  -> correct credentials: the request blocks while you approve MFA on your phone,
     then 200 + Set-Cookie: VIA_SESSION=<token>
  -> wrong credentials:   200, page titled "VIA Next/New Pin", Set-Cookie: CPnextpin=…
     (a RADIUS Access-Challenge page; posting any code to it yields "Login failed")

GET  https://remote.exeter.ac.uk/via/config?ikever=3&ak=1    (with VIA_SESSION)
  -> XML <via_profile> … </via_profile>  (gateway list, IKE/IPsec transforms, auth profile, user, role)
```

The tool saves the profile to `~/.via/profile.xml` and loads it with `via-cli -k PW profile side-load`.

Notes:
- The stock 4.7.6 client (GUI and CLI) treats the "Next/New Pin" page as a successful login, then fails
  with `Profile is in unexpected format` (a 401 on `/via/config`). That's why a wrong password produces a
  confusing error from the official app.
- With the correct password, we didn't test whether `via-cli profile load --gateway … --authprofile-index 1`
  works on its own. `exeter-vpn login` does the web step with `curl` and doesn't depend on it.

## Step 2: the tunnel (IKEv2/IPsec)

`via-cli vpn connect` (or the GUI) negotiates IKEv2 with the gateway. It authenticates with EAP-MSCHAPv2
using your username and password, then brings up the `via_vpn` interface:

- an address from the University range, e.g. `10.46.x.x/32`
- a **full tunnel**: routes `0.0.0.0/1`, `128.0.0.0/1`-style splits plus a host route to the gateway
- DNS `144.173.119.22` / `144.173.119.23`, search domain `ex.ac.uk`
- MTU **1250**, taken from `<via_mtu>` in the downloaded profile (the service log shows `mtu :"1250"`).
  `via_vpn` is a userspace `tun`; VIA encrypts itself and drops outgoing packets above
  `floor16(MTU + 2) - 2` (1250 gives 1246, 1240 gives 1230, 1220 gives 1214, 1246 gives 1246; incoming packets are
  unaffected). So starting VIA at 1246 (a value ≡ 14 mod 16) leaves no gap. `exeter-vpn connect` measures the
  cap once, sets the interface to it, and starts VIA there from then on. VIA's `Computed Path MTU` (1480 on a home link) is the
  outer path, not this cap.
- IPv4 only: IPv6 traffic isn't tunnelled, so on dual-stack networks it bypasses the VPN

## Logs

| File | Contents |
|---|---|
| `~/.via/app-via.log` | GUI/CLI side: web login, profile download (very verbose, includes HTTP headers) |
| `/usr/share/via/logs/app-vpn.log` | Service side: IKE, EAP, IPsec, routes, connect/disconnect reasons. Contains binary bytes, so use `grep -a` |
| `~/.via/last_error.log` | Last client error |

Useful service-log markers: `Received EAP SUCCESS!` (authenticated), `Global status file /vpn/status,…`
(state changes), `force disconnecting any existing on applications start` (the GUI started and killed your
tunnel). Endless `Cann't possible to send crypted frame -8807` lines are harmless noise while traffic flows.

## Files the client writes

- `~/.via/vpn_service_config.xml` contains your username **and plain-text password** (root-owned, mode 644 by
  default: `chmod 600` it)
- `~/.via/storage/` holds the keystore (CA certs), protected by the keystore password
- `~/.via/config.xml-tmp*` are leftover failed profile downloads (usually the login HTML), safe to delete
