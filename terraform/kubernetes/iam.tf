resource "yandex_iam_service_account" "cluster" { name = "notes-cluster" }
resource "yandex_iam_service_account" "node" { name = "notes-node" }
resource "yandex_iam_service_account" "gwin" { name = "notes-gwin" }
resource "yandex_resourcemanager_folder_iam_member" "cluster" {
  for_each  = toset(["k8s.clusters.agent", "vpc.publicAdmin", "load-balancer.admin"])
  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "node" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.node.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "gwin" {
  for_each  = toset(["alb.editor", "vpc.publicAdmin", "certificate-manager.certificates.downloader", "compute.viewer", "k8s.viewer", "logging.writer"])
  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.gwin.id}"
}
output "gwin_service_account_id" { value = yandex_iam_service_account.gwin.id }
