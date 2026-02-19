output "nas_volume_id"       { value = ncloud_nas_volume.main.id }
output "nas_mount_path"      { value = ncloud_nas_volume.main.mount_information }
output "media_bucket_name"   { value = ncloud_objectstorage_bucket.media.bucket_name }
output "static_bucket_name"  { value = ncloud_objectstorage_bucket.static.bucket_name }
output "backup_bucket_name"  { value = ncloud_objectstorage_bucket.backup.bucket_name }
