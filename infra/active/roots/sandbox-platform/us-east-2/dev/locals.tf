locals {
  platform_context = yamldecode(file("${path.root}/../../../../root-context.yaml"))
}
