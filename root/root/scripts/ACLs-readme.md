# Save and restore ACLs

For each folder backed up using Restic, ACLs are saved using the command
`getfacl -R $f > /tmp/ACLs/$(basename -- $f).acls.txt`

The /tmp/ACLs folder in then saved also usig Restic.

## Restore

1. restore the ACLs folder using restic (adjust depending on your hostname)
```
restic restore latest --path /tmp/ACLs --host geopresovregion.sk --target=/(see restic doc)
```
2. restore the ACLs for a given directory. For instance, restore acls for geoserver_geodata directory:
```
setfacl --restore=geoserver_geodata.acls.txt
```
