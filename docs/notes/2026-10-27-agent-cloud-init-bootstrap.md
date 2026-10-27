# Build agent bootstrap with cloud-init

## What I built
A cloud-init template that installs the Azure DevOps agent software at first boot
of the build agent virtual machine, with a pinned agent version.

## Why it exists
The virtual machine is recreated daily. Installing the agent by hand each time was
slow and error-prone. Only registration, which needs a credential, remains manual.

## How it works
Terraform renders a template with templatefile, base64-encodes it and passes it as
custom_data. On first boot cloud-init installs prerequisites, downloads the pinned
agent release with retries, extracts it as the unprivileged user and installs its
dependencies. The virtual machine depends explicitly on the NAT gateway
association so outbound connectivity exists when the download runs.

## What broke, and how I fixed it
A local plan wanted to replace the virtual machine, which would have destroyed
its registered agent. The cause was custom_data: my Windows checkout used CRLF line
endings (core.autocrlf=true) while the Linux pipeline used LF, so the encoded
content differed. Converting the local file to LF removed the replacement. The
permanent fix is a .gitattributes file forcing LF.

## Trade-offs
Changing custom_data replaces the virtual machine. The downloaded archive is not
yet verified against a checksum, which is a supply chain follow-up.

## Questions this answers in an interview
- How do you configure a VM at first boot with Terraform?
- Why can a local plan differ from the pipeline plan, and which do you trust?
- What forces a Terraform resource to be replaced, and how do you spot it?

## One-line pitch
A self-building agent machine with a pinned, reproducible install, and a
line-ending bug found by reading the plan before applying.