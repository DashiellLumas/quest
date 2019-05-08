
provider "aws" {
  region = "${var.region}" 
  shared_credentials_file = "${var.shared_credentials_file}"
  profile = "${var.profile}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags =  {
    Name = "main"
    Network =  "public"
    Application = "dash-quest-stack"
  }
}

resource "aws_subnet" "publicsubnet1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "publicsubnet2" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "public_route" {
  depends_on = ["aws_internet_gateway.internet_gateway"]
  route_table_id = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.internet_gateway.id}"
}

resource "aws_route_table_association" "publicsubnet1_association" {
  subnet_id = "${aws_subnet.publicsubnet1.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "publicsubnet2_association" {
  subnet_id = "${aws_subnet.publicsubnet2.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_ecs_cluster" "dashiellllumas_quest_cluster" {
  name = "dashiellllumas_quest_cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "DashECSTaskExecutionRole"
  path = "/"
  assume_role_policy = <<EOF
{
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": [
            "ecs-tasks.amazonaws.com"
          ]
        },
        "Effect": "Allow"
      }
    ]
}
EOF
}

resource "aws_iam_policy" "AmazonEC2ContainerServiceforEC2RolePolicy" {
  name =  "AmazonEC2ContainerServiceforEC2RolePolicy"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "ecs_task-attach" {
  name = "ecs_task-attach"
  roles = ["${aws_iam_role.ecs_task_execution_role.name}"]
  policy_arn = "${aws_iam_policy.AmazonEC2ContainerServiceforEC2RolePolicy.arn}"
}



resource "aws_ecs_task_definition" "service_task" {
  family = "service_task"
  cpu = "${var.ContainerCpu}"
  memory =  "${var.ContainerMemory}"
  network_mode = "awsvpc"
  requires_compatibilities =  ["FARGATE"]
  task_role_arn = "arn:aws:iam::581656899580:role/DashECSTaskExecutionRole"
  execution_role_arn = "arn:aws:iam::581656899580:role/DashECSTaskExecutionRole"
  container_definitions = "${file("task-definitions/service.json")}"
}

resource "aws_ecs_service" "fargate_service" {
  name = "fargate_service"
  cluster = "${aws_ecs_cluster.dashiellllumas_quest_cluster.arn}"
  task_definition = "${aws_ecs_task_definition.service_task.arn}"
  launch_type = "FARGATE"
  desired_count = 1
  # iam_role = "arn:aws:iam::581656899580:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  network_configuration {
    assign_public_ip =  "true"
    security_groups = ["${aws_security_group.application_container_security_group.id}"] 
    subnets = ["${aws_subnet.publicsubnet1.id}", "${aws_subnet.publicsubnet2.id}"]
  }
  load_balancer {
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
    container_name = "dashielllumas-quest"
    container_port = 80
  }
  depends_on = ["aws_ecs_cluster.dashiellllumas_quest_cluster","aws_alb.alb", "aws_alb_listener.alb_listener", "aws_alb_target_group.target_group" ]
}

# resource "aws_iam_service_linked_role" "service_scheduler_role" {
#   aws_service_name = "ecs.amazonaws.com"
# }

# resource "aws_iam_policy" "service_scheduler_role_policy" {
#   name =  "service_scheduler_role_policy"
#   path = "/"

#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Action": [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:Describe*",
#           "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
#           "elasticloadbalancing:DeregisterTargets",
#           "elasticloadbalancing:Describe*",
#           "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
#           "elasticloadbalancing:RegisterTargets"
#         ],
#         "Effect": "Allow",
#         "Resource": "*"
#       }
#     ]
# }
# EOF
# }

# resource "aws_iam_policy_attachment" "ecs_scheduler-attach" {
#   name = "ecs_scheduler-attach"
#   roles = ["${aws_iam_role.service_scheduler_role.name}"]
#   policy_arn = "${aws_iam_policy.service_scheduler_role_policy.arn}"
# }

resource "aws_alb" "alb" {
  name = "quest-terraform-alb"
  internal = false
  load_balancer_type = "${var.load_balancer_type}"
  ip_address_type = "${var.ip_address_type}"
  security_groups = ["${aws_security_group.alb_security_group.id}"]
  subnets = ["${aws_subnet.publicsubnet1.id}", "${aws_subnet.publicsubnet2.id}"]
  
}

resource "aws_route53_record" "load_balancer_alias" {
  zone_id = "${var.Route53HostedZoneID}"
  name = "${var.Route53Prefix}-origin.${var.Route53HostedZoneDomainName}"
  type = "A"

  alias {
    name = "${aws_alb.alb.dns_name}"
    zone_id = "${aws_alb.alb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_alb_target_group" "target_group" {
  name = "target-group"
  port = 80,
  protocol = "HTTP",
  target_type = "ip"
  vpc_id = "${aws_vpc.main.id}"
  depends_on = ["aws_alb.alb"]
}

resource "aws_alb_listener" "alb_listener" {
  certificate_arn = "arn:aws:acm:us-east-2:581656899580:certificate/6e5b86da-9b6b-4836-8de4-1c26dc09b1fc"
  port = 443
  protocol = "HTTPS"
  load_balancer_arn = "${aws_alb.alb.arn}"
  default_action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
  }
  depends_on = ["aws_alb.alb", "aws_alb_target_group.target_group"]
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {

  enabled = true
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  aliases = ["dashielllumas.quest.rearc.io"]
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    
    target_origin_id = "${aws_route53_record.load_balancer_alias.name}"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
       cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = "dashielllumas-origin.quest.rearc.io"
    custom_origin_config {
      origin_ssl_protocols = ["TLSv1"]
      http_port = 80
      https_port = 443
      origin_protocol_policy = "match-viewer"
    }
    origin_id = "${aws_route53_record.load_balancer_alias.name}"
  } 
  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:581656899580:certificate/26728320-bb28-41ee-a2cc-37d0d4ef3fd4"
    ssl_support_method = "sni-only"
  }
}

resource "aws_route53_record" "cloudfront_alias" {
  type = "A"
  zone_id = "${var.Route53HostedZoneID}"
  name = "${var.Route53Prefix}.${var.Route53HostedZoneDomainName}"
  alias {
    name = "${aws_cloudfront_distribution.cloudfront_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group" "alb_security_group" {
  name  = "application-load-balancer-sg"
  description = "Allow access on port 443 from 0.0.0.0/0"
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443,
    to_port = 443
  }
}

resource "aws_security_group" "application_container_security_group" {
  name = "application-container-sg"
  description =  "Allow incoming traffic from Application Load Balancer on port 80"
  vpc_id = "${aws_vpc.main.id}"
  depends_on = ["aws_security_group.alb_security_group"]

  ingress {
    protocol = "tcp"
    from_port = 80,
    to_port = 80,
    security_groups = ["${aws_security_group.alb_security_group.id}"]
  }
}










