DirectPV Smoke Test
-------------------
> Sanity check to make sure the installation worked.

After installing DirectPV

```bash
$ kubectl directpv install
```

check the `info` command works fine

```bash
$ kubectl directpv info
```

Then make DirectPV pick up, format and add to its stash your drives

```bash
$ kubectl directpv discover
# review the content of `drives.yaml` before running the command below!
$ kubectl directpv init --dangerous drives.yaml
$ kubectl directpv list drives
```

The output of the last command should show DirectPV now manages your
drives.

Now you're ready to run a basic test to make sure you can actually
use DirectPV-backed storage. The K8s resources in this directory
define a PVC with a storage class of `directpv-min-io` and a pod
to use it in a `test` namespace. Start the show with

```bash
$ kustomize build  | kubectl apply -f -
```

If everything goes well, you should be able to exec a shell in the
`test-pod` and see a `/mnt/test.txt` file with a South African greeting
in it. You should also be able to see the same file on the actual
node hard drive in one of the sub-dirs of `/var/lib/directpv/mnt/`.

If all hell breaks loose, roll up your sleeves to collect lots of
debug info and then open an issue similar to this one:
- https://github.com/minio/directpv/issues/816
