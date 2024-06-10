## Install OpenTofu on Linux

On your Linux workstation run the following scripts to install OpenTofu. See [here]for latest instructions and other platform information. 

```bash title="Download the installer script:"
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
```
```bash title="Give it execution permissions:"
chmod +x install-opentofu.sh
```
```bash title="Run the installer:"
./install-opentofu.sh --install-method rpm
```

## Install OpenTofu on Windows

On your Windows workstation run the following scripts to install OpenTofu.

```PowerShell title="Download the installer script:"
Invoke-WebRequest -outfile "install-opentofu.ps1" -uri "https://get.opentofu.org/install-opentofu.ps1"
```
```PowerShell title="Run the installer"
& .\install-opentofu.ps1 -installMethod standalone
```
```PowerShell title="Remove the installer"
Remove-Item install-opentofu.ps1
```

