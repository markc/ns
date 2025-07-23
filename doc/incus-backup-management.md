# Incus Backup Management

## Removing Internal Backups

To delete internal backups (shown in `incus info <container>` under "Backups" section), use the Incus REST API:

```bash
incus query -X DELETE --wait /1.0/instances/<container>/backups/<backup_name>
```

### Example
```bash
# Delete specific backups from mgo container
incus query -X DELETE --wait /1.0/instances/mgo/backups/backup0
incus query -X DELETE --wait /1.0/instances/mgo/backups/backup1
```

### Notes
- Regular `incus delete` command only works for snapshots, not internal backups
- Internal backups have expiry dates and will auto-cleanup when expired
- Use `incus info <container>` to see current backups and their expiry times