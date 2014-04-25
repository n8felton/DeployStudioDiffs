DeployStudioDiffs
-----------------

Tracking changes to DeployStudio stable and nightly versions since 1.6.3.

This is done somewhat by brute force, by checking in the entire DeployStudio Admin.app into this Git repo. The Admin app includes the Runtime and Assistant apps (and their scripts) and the server binary itself.

Each release is added as a single, tagged commit. You can simply compare by commits or compare across tags. It's possible that if the git-tracked files pattern is later updated, that the entire repo's history will have tone rebuilt, so it's recommended to share any comparison URLs using tags instead of commit hashes, which may change some time in the future.

For example, to compare 1.6.4-NB140227 to 1.6.4-NB140303, just refer to these release names prepended with a 'v':

[https://github.com/timsutton/DeployStudioDiffs/compare/v1.6.4-NB140227...v1.6.4-NB140303](https://github.com/timsutton/DeployStudioDiffs/compare/v1.6.4-NB140227...v1.6.4-NB140303)
