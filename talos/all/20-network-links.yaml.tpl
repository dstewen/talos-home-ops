---
apiVersion: v1alpha1
kind: LinkAliasConfig
name: ethSel0
selector:
  match: glob("{{ .Node.Data.macAddr }}", mac(link.hardware_addr))
---
apiVersion: v1alpha1
kind: BondConfig
name: bond0
links:
  - ethSel0
bondMode: active-backup
mtu: {{ .Node.Data.mtu }}
addresses:
  - address: "{{ .Node.IP }}/24"
routes:
  - gateway: "10.200.15.1"
{{- if eq .Node.Role "control-plane" }}
---
apiVersion: v1alpha1
kind: Layer2VIPConfig
link: bond0
name: "10.200.15.254"
{{- end }}
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.20
vlanID: 20
parent: bond0
mtu: 1500
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.30
vlanID: 30
parent: bond0
mtu: 1500
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.100
vlanID: 100
parent: bond0
mtu: 1500
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.110
vlanID: 110
parent: bond0
mtu: 1500
