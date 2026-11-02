#################################### whatsapp start ####################################
# WhatsApp (AWS End User Messaging Social, ap-south-2). The WABA "KIET Deemed To Be University ERP"
# (waba-6a5ef3eb66954956a579ee36fc414bcb) posts message and status events to SNS topic whatsapp3,
# which was set up by hand and also feeds other subscribers. Only the backend subscription is managed here.
# EduVverse WhatsApp account form: SNS topic ARN = data.aws_sns_topic.whatsapp.arn, media bucket = wa-kiet-media.

variable "whatsapp_webhook_url" {
  description = "Backend webhook for WhatsApp events; the backend confirms the subscription itself. Empty = no subscription."
  type        = string
  default     = "https://backend.kiet.eduvverse.com/v1/communication_whatsapp/webhook/"
}

data "aws_sns_topic" "whatsapp" {
  name = "whatsapp3"
}

resource "aws_sns_topic_subscription" "whatsapp_webhook" {
  count                  = var.whatsapp_webhook_url == "" ? 0 : 1
  topic_arn              = data.aws_sns_topic.whatsapp.arn
  protocol               = "https"
  endpoint               = var.whatsapp_webhook_url
  endpoint_auto_confirms = true
}
#################################### whatsapp end ####################################
