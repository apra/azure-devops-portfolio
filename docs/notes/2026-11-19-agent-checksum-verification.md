# Verifying the build agent download against a published checksum

## What I built
The build agent's first-boot configuration verifies the downloaded agent archive
against the SHA-256 value published in the vendor's release notes. If the values
differ, the script removes the archive and stops before anything is installed.

## Why it exists
The agent runs inside the network and holds the means to deploy to Azure. It was
the one component downloaded from the internet and installed without
verification. A corrupted, interrupted or substituted archive would have been
installed silently. Verifying what is installed is standard supply chain
practice. It is recorded in the status update of ADR 0005.

## How it works
- A checksum is a fixed-length fingerprint calculated from every byte of a file.
  Any change to the file changes the fingerprint.
- The expected value is stored beside the agent version in the Terraform locals,
  because a hash is valid for one exact file. The comment next to it states that
  both must change together.
- Terraform passes the value to the first-boot template. After the download, the
  template runs the check with `sha256sum -c`. On a mismatch it prints a message,
  deletes the archive and exits.
- The expected value comes from the GitHub release notes, while the file comes
  from the vendor's download host. Two separate channels mean a tampered
  download cannot supply its own matching hash.

## What broke, and how I fixed it
1. **Obtaining the value.** The published hash could not be retrieved
   automatically for this exact version, and values for other versions were not
   used. The value was copied by hand from the release page for the correct
   package, and then compared with the stored copy character for character.
2. **A missing template edit.** The first attempt added the value to the
   Terraform locals but not to the template. Terraform ignores a template
   variable that is never used, so nothing failed, and the check was silently
   absent. Searching the template for the variable name found the omission.
   Checks that print an explicit answer are used for this reason.
3. **Formatter failure in CI.** The formatting check failed on two whitespace
   points: comment lines between attributes break the formatter's alignment
   groups, and a trailing space remained on one line. Running the formatter
   locally with a diff showed both, and the fix was committed to the same
   branch.
4. **Failure path not yet exercised.** The design depends on `exit` stopping the
   first-boot script. cloud-init runs the commands of `runcmd` as one shell
   script, so this is expected to work, but it has not been demonstrated. At the
   start of the next build session the correct value is first shown to pass, and
   the failure is then tested once with a deliberately incorrect value.

## Trade-offs
- The hash must be updated with every version change. Forgetting causes a
  deliberate, safe boot failure and not a silent installation.
- A checksum proves integrity, not authenticity. The release notes and the
  download are both published by the vendor, so a compromise of the vendor itself
  would not be detected. Signature verification would address that, but these
  releases publish checksums only.
- Building the agent into a prepared image would remove the download from first
  boot entirely, at the cost of image management.

## Questions this answers in an interview
- What is a checksum, and how does it differ from a signature?
- Why must the expected value come from a different channel than the download?
- How do you verify third-party software installed by automation?
- How would you prove that a safety check actually fails when it should?
- What are the alternatives to downloading software at boot?

## One-line pitch
The agent is installed only if it matches the vendor's published checksum, and the
check stops the boot sequence when it does not.
