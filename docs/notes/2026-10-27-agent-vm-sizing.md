# Build agent VM sizing and SKU availability

## What I built
The build agent virtual machine on Standard_D2nls_v6, Ubuntu 24.04, no public IP,
SSH key only, with a system-assigned managed identity.

## Why it exists
The private agent runs pipeline jobs inside the network.

## How it works
This size supports only the NVMe disk controller, so the VM sets
disk_controller_type to NVMe.

## What broke, and how I fixed it
The first choice, Standard_B1s, failed with SkuNotAvailable. Quota and
availability are separate controls: quota limits how much you may use, while a
subscription restriction removes a size from what you may create. Listing sizes
with az vm list-skus --all showed a NotAvailableForSubscription restriction on
every B-series size in the region, including the newer Bsv2 family, so raising
quota would not have helped. I chose Standard_D2nls_v6, which was available and had
quota.

## Trade-offs
The chosen size is a paid size where the burstable options were cheaper. A
support request to lift the restriction is possible but slow. The VM is destroyed
after each session to limit cost.

## Questions this answers in an interview
- What is the difference between a quota error and a SKU restriction?
- How do you find which VM sizes you can actually create?

## One-line pitch
Diagnosed an availability restriction that looked like a quota problem and chose
a workable size instead of waiting on a ticket.