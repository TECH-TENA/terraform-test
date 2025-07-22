resource "aws_sns_topic" "budget_alerts" {
  name = format("%s-%s-aws-budget-alerts", var.tags["environment"], var.tags["project"])
}

resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each = toset(var.config.email_subscribers)

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_budgets_budget" "monthly_budget" {
  name = format("%s-%s-monthly-budget", var.tags["environment"], var.tags["project"])
  budget_type  = "COST"
  limit_amount = var.config.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = var.config.thresholds
    content {
      comparison_operator         = "GREATER_THAN"
      threshold                   = notification.value
      threshold_type              = "PERCENTAGE"
      notification_type           = "ACTUAL"
      subscriber_email_addresses  = var.config.email_subscribers
    }
  }
}
