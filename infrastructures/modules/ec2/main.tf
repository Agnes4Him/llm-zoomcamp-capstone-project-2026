data "aws_caller_identity" "current" {}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-instance-profile"
  role = var.role_name
}

resource "aws_key_pair" "healthsecure" {
  key_name   = "llm-project-key"
  public_key = var.public_key
}

resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    var.security_group_id
  ]

  key_name             = aws_key_pair.healthsecure.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"

    delete_on_termination = true
  }

  user_data = templatefile(
    "${path.module}/user-data.sh.tpl",
    {
      flux_repo = templatefile(
        "${path.root}./kubernetes/supporting-services/flux/oci-repository.yaml",
        {
          account_id = data.aws_caller_identity.current.account_id
          region     = var.aws_region
        }
      )

      flux_kustomization = file("${path.root}./kubernetes/supporting-services/flux/kustomization.yaml")
      gateway            = file("${path.root}./kubernetes/supporting-services/traefik/gateway.yaml")

      grafana_namespace  = file("${path.root}./kubernetes/supporting-services/grafana/namespace.yaml")
      grafana_deployment = file("${path.root}./kubernetes/supporting-services/grafana/deployment.yaml")
      grafana_service    = file("${path.root}./kubernetes/supporting-services/grafana/service.yaml")
      grafana_httproute  = file("${path.root}./kubernetes/supporting-services/grafana/httproute.yaml")
    }
  )

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }
}