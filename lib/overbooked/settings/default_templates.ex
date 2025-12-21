defmodule Overbooked.Settings.DefaultTemplates do
  @moduledoc """
  Provides default email template content.
  These are used when no custom template exists in the database.
  """

  @doc """
  Returns the default subject line for a template type.
  """
  def default_subject("welcome"), do: "Welcome to Hatchbridge Rooms"
  def default_subject("password_reset"), do: "Reset your password"
  def default_subject("update_email"), do: "Update email instructions"
  def default_subject("contract_confirmation"), do: "Your contract is confirmed"
  def default_subject("contract_cancelled"), do: "Contract cancelled"
  def default_subject("refund_notification"), do: "Refund processed for your contract"
  def default_subject("booking_reminder"), do: "Reminder: Your booking is tomorrow"
  def default_subject("contract_expiration_warning"), do: "Your contract expires soon"
  def default_subject(_), do: "Hatchbridge Rooms Notification"

  @doc """
  Returns the default HTML body for a template type.
  Note: Uses {{variable}} syntax for admin-editable templates.
  """
  def default_html_body("welcome") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Welcome to Hatchbridge Rooms
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Welcome to Hatchbridge Rooms! Your account has been created and you're ready to start booking workspaces.
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Click the button below to confirm your email address and get started:
    </p>

    <p style="margin-bottom: 32px;">
      <a href="{{url}}" style="display: inline-block; padding: 14px 28px; background-color: #FFC421; color: #000824; text-decoration: none; border-radius: 6px; font-weight: 600;">
        Confirm Email & Get Started
      </a>
    </p>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Here's what you can do:
    </p>

    <ul style="margin: 0 0 24px; padding-left: 24px; color: #374151; font-size: 16px; line-height: 24px;">
      <li style="margin-bottom: 8px;">Browse and book available rooms and desks</li>
      <li style="margin-bottom: 8px;">View your upcoming bookings</li>
      <li style="margin-bottom: 8px;">Manage your workspace preferences</li>
    </ul>

    <p style="margin: 0; color: #374151; font-size: 16px; line-height: 24px;">
      If you have any questions, feel free to reach out to our support team.
    </p>
    """
  end

  def default_html_body("password_reset") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Reset your password
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Someone requested a password reset for your account. If this was you, click the button below to reset your password:
    </p>

    <p style="margin-bottom: 24px;">
      <a href="{{url}}" style="display: inline-block; padding: 14px 28px; background-color: #FFC421; color: #000824; text-decoration: none; border-radius: 6px; font-weight: 600;">
        Reset Password
      </a>
    </p>

    <p style="margin: 0 0 16px; color: #6b7280; font-size: 14px; line-height: 20px;">
      If you didn't request this, you can safely ignore this email. Your password will not be changed.
    </p>

    <p style="margin: 0; color: #6b7280; font-size: 14px; line-height: 20px;">
      This link will expire in 24 hours.
    </p>
    """
  end

  def default_html_body("update_email") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Update your email address
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      You can change your email by clicking the link below:
    </p>

    <p style="margin-bottom: 24px;">
      <a href="{{url}}" style="display: inline-block; padding: 14px 28px; background-color: #FFC421; color: #000824; text-decoration: none; border-radius: 6px; font-weight: 600;">
        Update Email Address
      </a>
    </p>

    <p style="margin: 0; color: #6b7280; font-size: 14px; line-height: 20px;">
      If you didn't request this change, please ignore this email.
    </p>
    """
  end

  def default_html_body("contract_confirmation") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Your contract is confirmed!
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Thank you for your payment! Your office space contract has been activated. Here are the details:
    </p>

    <table style="width: 100%; background-color: #f9fafb; border-radius: 8px; margin-bottom: 24px;">
      <tr>
        <td style="padding: 24px;">
          <p style="margin: 0 0 16px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Space
          </p>
          <p style="margin: 0 0 16px; font-size: 18px; color: #111827; font-weight: 600;">
            {{contract.resource.name}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Contract Period
          </p>
          <p style="margin: 0 0 16px; font-size: 16px; color: #111827;">
            {{contract.start_date}} to {{contract.end_date}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Duration
          </p>
          <p style="margin: 0 0 16px; font-size: 16px; color: #111827;">
            {{contract.duration_months}} month(s)
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Total Paid
          </p>
          <p style="margin: 0; font-size: 20px; color: #059669; font-weight: 700;">
            {{contract.total_amount}}
          </p>
        </td>
      </tr>
    </table>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Your space is now ready for you to use. We look forward to seeing you!
    </p>

    <p style="margin: 0; color: #6b7280; font-size: 14px; line-height: 20px;">
      If you have any questions, please don't hesitate to contact us.
    </p>
    """
  end

  def default_html_body("contract_cancelled") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Contract Cancelled
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Your office space contract has been cancelled. Here are the details of the cancelled contract:
    </p>

    <table style="width: 100%; background-color: #fef2f2; border-radius: 8px; border-left: 4px solid #ef4444; margin-bottom: 24px;">
      <tr>
        <td style="padding: 24px;">
          <p style="margin: 0 0 16px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Space
          </p>
          <p style="margin: 0 0 16px; font-size: 18px; color: #111827; font-weight: 600;">
            {{contract.resource.name}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Original Contract Period
          </p>
          <p style="margin: 0 0 16px; font-size: 16px; color: #111827;">
            {{contract.start_date}} to {{contract.end_date}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Status
          </p>
          <p style="margin: 0; font-size: 16px; color: #dc2626; font-weight: 600;">
            Cancelled
          </p>
        </td>
      </tr>
    </table>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      If you have any questions about this cancellation or would like to rent another space, please don't hesitate to reach out.
    </p>
    """
  end

  def default_html_body("refund_notification") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Refund Processed
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      We've processed a refund for your office space contract. Here are the details:
    </p>

    <table style="width: 100%; background-color: #fef3c7; border-radius: 8px; border-left: 4px solid #f59e0b; margin-bottom: 24px;">
      <tr>
        <td style="padding: 24px;">
          <p style="margin: 0 0 16px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Space
          </p>
          <p style="margin: 0 0 16px; font-size: 18px; color: #111827; font-weight: 600;">
            {{contract.resource.name}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Refund Amount
          </p>
          <p style="margin: 0 0 16px; font-size: 20px; color: #059669; font-weight: 700;">
            {{contract.refund_amount}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Refund ID
          </p>
          <p style="margin: 0; font-size: 14px; color: #6b7280; font-family: monospace;">
            {{contract.refund_id}}
          </p>
        </td>
      </tr>
    </table>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      The refund has been initiated and should appear in your original payment method within <strong>5-10 business days</strong>, depending on your bank or card issuer.
    </p>

    <p style="margin: 0; color: #374151; font-size: 16px; line-height: 24px;">
      If you have any questions about this refund or would like to rent another space, please don't hesitate to reach out.
    </p>
    """
  end

  def default_html_body("booking_reminder") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Booking Reminder
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      This is a friendly reminder that you have a booking coming up tomorrow.
    </p>

    <table style="width: 100%; background-color: #f0f9ff; border-radius: 8px; border-left: 4px solid #0ea5e9; margin-bottom: 24px;">
      <tr>
        <td style="padding: 24px;">
          <p style="margin: 0 0 16px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Resource
          </p>
          <p style="margin: 0 0 16px; font-size: 18px; color: #111827; font-weight: 600;">
            {{booking.resource.name}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Date
          </p>
          <p style="margin: 0 0 16px; font-size: 16px; color: #111827;">
            {{booking.date}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Time
          </p>
          <p style="margin: 0; font-size: 16px; color: #111827;">
            {{booking.start_time}} - {{booking.end_time}}
          </p>
        </td>
      </tr>
    </table>

    <p style="margin: 0; color: #374151; font-size: 16px; line-height: 24px;">
      We look forward to seeing you!
    </p>
    """
  end

  def default_html_body("contract_expiration_warning") do
    """
    <h1 style="font-size: 24px; font-weight: 700; margin: 0 0 24px; color: #111827;">
      Contract Expiring Soon
    </h1>

    <p style="margin: 0 0 16px; color: #374151; font-size: 16px; line-height: 24px;">
      Hi {{user.name}},
    </p>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      Your office space contract is expiring in {{contract.days_remaining}} days. Here are the details:
    </p>

    <table style="width: 100%; background-color: #fef3c7; border-radius: 8px; border-left: 4px solid #f59e0b; margin-bottom: 24px;">
      <tr>
        <td style="padding: 24px;">
          <p style="margin: 0 0 16px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Space
          </p>
          <p style="margin: 0 0 16px; font-size: 18px; color: #111827; font-weight: 600;">
            {{contract.resource.name}}
          </p>

          <p style="margin: 0 0 8px; font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600;">
            Expires On
          </p>
          <p style="margin: 0; font-size: 16px; color: #111827;">
            {{contract.end_date}}
          </p>
        </td>
      </tr>
    </table>

    <p style="margin: 0 0 24px; color: #374151; font-size: 16px; line-height: 24px;">
      If you'd like to renew your contract or explore other available spaces, please visit our office spaces page or contact us.
    </p>

    <p style="margin: 0; color: #6b7280; font-size: 14px; line-height: 20px;">
      Thank you for being a valued member of our community.
    </p>
    """
  end

  def default_html_body(_), do: "<p>Email content</p>"

  @doc """
  Returns the default text body for a template type.
  """
  def default_text_body("welcome") do
    """
    Welcome to Hatchbridge Rooms

    Hi {{user.name}},

    Welcome to Hatchbridge Rooms! Your account has been created and you're ready to start booking workspaces.

    Click the link below to confirm your email address and get started:

    {{url}}

    Here's what you can do:

    - Browse and book available rooms and desks
    - View your upcoming bookings
    - Manage your workspace preferences

    If you have any questions, feel free to reach out to our support team.
    """
  end

  def default_text_body("password_reset") do
    """
    Reset your password

    Hi {{user.name}},

    Someone requested a password reset for your account. If this was you, click the link below to reset your password:

    {{url}}

    If you didn't request this, you can safely ignore this email. Your password will not be changed.

    This link will expire in 24 hours.
    """
  end

  def default_text_body("update_email") do
    """
    Update your email address

    Hi {{user.name}},

    You can change your email by visiting the URL below:

    {{url}}

    If you didn't request this change, please ignore this.
    """
  end

  def default_text_body("contract_confirmation") do
    """
    Your contract is confirmed!

    Hi {{user.name}},

    Thank you for your payment! Your office space contract has been activated.

    CONTRACT DETAILS
    ================

    Space: {{contract.resource.name}}

    Contract Period: {{contract.start_date}} to {{contract.end_date}}

    Duration: {{contract.duration_months}} month(s)

    Total Paid: {{contract.total_amount}}

    ================

    Your space is now ready for you to use. We look forward to seeing you!

    If you have any questions, please don't hesitate to contact us.
    """
  end

  def default_text_body("contract_cancelled") do
    """
    Contract Cancelled

    Hi {{user.name}},

    Your office space contract has been cancelled.

    CANCELLED CONTRACT DETAILS
    ==========================

    Space: {{contract.resource.name}}

    Original Contract Period: {{contract.start_date}} to {{contract.end_date}}

    Status: Cancelled

    ==========================

    If you have any questions about this cancellation or would like to rent another space, please don't hesitate to reach out.
    """
  end

  def default_text_body("refund_notification") do
    """
    Refund Processed

    Hi {{user.name}},

    We've processed a refund for your office space contract.

    REFUND DETAILS
    ==============

    Space: {{contract.resource.name}}

    Refund Amount: {{contract.refund_amount}}

    Refund ID: {{contract.refund_id}}

    ==============

    The refund has been initiated and should appear in your original payment method within 5-10 business days, depending on your bank or card issuer.

    If you have any questions about this refund or would like to rent another space, please don't hesitate to reach out.
    """
  end

  def default_text_body("booking_reminder") do
    """
    Booking Reminder

    Hi {{user.name}},

    This is a friendly reminder that you have a booking coming up tomorrow.

    BOOKING DETAILS
    ===============

    Resource: {{booking.resource.name}}

    Date: {{booking.date}}

    Time: {{booking.start_time}} - {{booking.end_time}}

    ===============

    We look forward to seeing you!
    """
  end

  def default_text_body("contract_expiration_warning") do
    """
    Contract Expiring Soon

    Hi {{user.name}},

    Your office space contract is expiring in {{contract.days_remaining}} days.

    CONTRACT DETAILS
    ================

    Space: {{contract.resource.name}}

    Expires On: {{contract.end_date}}

    ================

    If you'd like to renew your contract or explore other available spaces, please visit our office spaces page or contact us.

    Thank you for being a valued member of our community.
    """
  end

  def default_text_body(_), do: "Email content"
end
