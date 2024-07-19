resource "nutanix_karbon_cluster" "example_cluster" {
  name       = "example_cluster"
  version    = "1.25.6-0"
  storage_class_config {
    reclaim_policy = "Delete"
    volumes_config {
      file_system                = "ext4"
      flash_mode                 = false
      password                   = var.password
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
      storage_container          = var.storage_container
      username                   = var.user
    }
  }
  cni_config {
    node_cidr_mask_size = 24
    pod_ipv4_cidr       = "172.20.0.0/16"
    service_ipv4_cidr   = "172.19.0.0/16"
  }
  worker_node_pool {
    node_os_version = var.os_version
    num_instances   = 1
    ahv_config {
      network_uuid               = data.nutanix_subnet.subnet.id
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
    }
  }
  etcd_node_pool {
    node_os_version = var.os_version
    num_instances   = 1
    ahv_config {
      network_uuid               = data.nutanix_subnet.subnet.id
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
    }
  }
  master_node_pool {
    node_os_version = var.os_version
    num_instances   = 1
    ahv_config {
      network_uuid               = data.nutanix_subnet.subnet.id
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
    }
  }
  timeouts {
    create = "1h"
    update = "30m"
    delete = "10m"
    }
}