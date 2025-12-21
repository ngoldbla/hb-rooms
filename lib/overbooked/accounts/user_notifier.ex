defmodule Overbooked.Accounts.UserNotifier do
  import Swoosh.Email

  alias Overbooked.Mailer
  alias Overbooked.Settings
  alias Overbooked.EmailRenderer
  alias OverbookedWeb.EmailView

  # Delivers the email using the application mailer (plain text only).
  defp deliver(recipient, subject, body) do
    {from_name, from_email} = get_from_address()

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Delivers email using DB-stored templates with variable substitution.
  defp deliver_from_template(recipient, template_type, assigns) do
    {from_name, from_email} = get_from_address()

    template = get_email_template(template_type)

    # Build assigns for variable substitution
    renderer_assigns = build_renderer_assigns(assigns)

    # Render subject with variables
    rendered_subject = EmailRenderer.render(template.subject, renderer_assigns)

    # Render HTML body wrapped in email layout
    rendered_html = render_email_with_layout(template.html_body, renderer_assigns)

    # Render text body with variables
    rendered_text = EmailRenderer.render(template.text_body || "", renderer_assigns)

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(rendered_subject)
      |> html_body(rendered_html)
      |> text_body(rendered_text)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Delivers multipart email (HTML + text) using file-based templates.
  # Used for templates that don't have DB customization (e.g., booking_confirmation).
  defp deliver_multipart(recipient, subject, template, assigns) do
    {from_name, from_email} = get_from_address()

    base_assigns =
      assigns
      |> Map.put(:subject, subject)
      |> Map.put_new(:preheader, "")
      |> Map.put(:logo_url, "#{OverbookedWeb.Endpoint.url()}/images/hatchbridge-logo.svg")
      |> Map.put(:base_url, OverbookedWeb.Endpoint.url())
      |> Map.put(:current_year, Date.utc_today().year)

    # Render HTML email
    html_body =
      EmailView.render(template <> ".html", base_assigns)
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Render text email
    text_body =
      EmailView.render(template <> ".text", base_assigns)
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> html_body(html_body)
      |> text_body(text_body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp get_email_template(template_type) do
    if Process.whereis(Overbooked.Repo) do
      try do
        Settings.get_email_template(template_type)
      rescue
        _ -> Settings.get_default_template(template_type)
      end
    else
      Settings.get_default_template(template_type)
    end
  end

  defp build_renderer_assigns(assigns) do
    base = %{
      base_url: OverbookedWeb.Endpoint.url()
    }

    Map.merge(base, format_assigns_for_renderer(assigns))
  end

  defp format_assigns_for_renderer(assigns) do
    assigns
    |> Enum.reduce(%{}, fn
      {:user, user}, acc ->
        Map.put(acc, :user, %{
          name: user.name || user.email,
          email: user.email
        })

      {:contract, contract}, acc ->
        contract_data = %{
          resource: %{
            name: contract.resource.name,
            description: contract.resource.description
          },
          start_date: format_date(contract.start_date),
          end_date: format_date(contract.end_date),
          duration_months: to_string(contract.duration_months),
          total_amount: format_price(contract.total_amount_cents),
          refund_amount: format_price(contract.refund_amount_cents),
          refund_id: contract.refund_id || ""
        }

        # Add days_remaining if present (for expiration warnings)
        contract_data =
          if Map.has_key?(contract, :days_remaining) do
            Map.put(contract_data, :days_remaining, to_string(contract.days_remaining))
          else
            contract_data
          end

        Map.put(acc, :contract, contract_data)

      {:booking, booking}, acc ->
        Map.put(acc, :booking, %{
          resource: %{
            name: booking.resource.name
          },
          date: format_date(DateTime.to_date(booking.start_at)),
          start_time: format_time(booking.start_at),
          end_time: format_time(booking.end_at)
        })

      {:url, url}, acc ->
        Map.put(acc, :url, url)

      {key, value}, acc when is_binary(value) or is_number(value) ->
        Map.put(acc, key, value)

      _, acc ->
        acc
    end)
  end

  defp format_date(nil), do: ""
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%B %d, %Y")
  defp format_date(date), do: to_string(date)

  defp format_time(nil), do: ""
  defp format_time(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%I:%M %p")
  defp format_time(_), do: ""

  defp format_price(nil), do: "$0.00"
  defp format_price(cents) when is_integer(cents) do
    dollars = cents / 100
    "$#{:erlang.float_to_binary(dollars, decimals: 2)}"
  end

  defp render_email_with_layout(content, assigns) do
    rendered_content = EmailRenderer.render(content, assigns)
    base_url = OverbookedWeb.Endpoint.url()

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="color-scheme" content="light dark">
      <style>
        :root { color-scheme: light dark; }
        body, table, td { margin: 0; padding: 0; }
        img { border: 0; display: block; max-width: 100%; }
        @media (prefers-color-scheme: dark) {
          .email-bg { background-color: #1a1a2e !important; }
          .content-bg { background-color: #000824 !important; }
          .text-primary { color: #ffffff !important; }
          .text-secondary { color: #a0aec0 !important; }
        }
        @media only screen and (max-width: 600px) {
          .container { width: 100% !important; }
          .content-padding { padding: 24px 16px !important; }
        }
      </style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f4f4f5; font-family: 'Nunito Sans', Arial, sans-serif;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="email-bg" style="background-color: #f4f4f5;">
        <tr>
          <td align="center" style="padding: 40px 20px;">
            <table role="presentation" class="container" width="600" cellpadding="0" cellspacing="0">
              <tr>
                <td align="center" style="padding-bottom: 32px;">
                  <img src="#{base_url}/images/hatchbridge-logo.svg" alt="Hatchbridge Rooms" width="180" style="height: auto;">
                </td>
              </tr>
              <tr>
                <td class="content-bg content-padding" style="background-color: #ffffff; border-radius: 12px; padding: 40px;">
                  #{rendered_content}
                </td>
              </tr>
              <tr>
                <td align="center" style="padding-top: 32px;">
                  <p class="text-secondary" style="margin: 0; color: #6b7280; font-size: 12px;">
                    Hatchbridge Rooms<br>
                    <a href="#{base_url}" style="color: #6b7280;">Visit Dashboard</a>
                  </p>
                  <p style="margin: 16px 0 0; color: #9ca3af; font-size: 11px;">
                    &copy; #{Date.utc_today().year} Hatchbridge. All rights reserved.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
  end

  defp get_from_address do
    # Try to get from database settings first
    case get_mail_config() do
      %{from_name: name, from_email: email} when not is_nil(email) ->
        {name, email}

      _ ->
        # Fall back to application config or defaults
        config = Application.get_env(:overbooked, :mail_defaults, [])
        name = Keyword.get(config, :from_name, "Hatchbridge Rooms")
        email = Keyword.get(config, :from_email, "noreply@example.com")
        {name, email}
    end
  end

  defp get_mail_config do
    if Process.whereis(Overbooked.Repo) do
      try do
        Overbooked.Settings.get_mailgun_config()
      rescue
        _ -> nil
      end
    else
      nil
    end
  end

  @doc """
  Deliver instructions to confirm account (invitation).
  """
  def deliver_user_invitation_instructions(email, url) do
    user = %{name: email, email: email}

    deliver_from_template(
      email,
      "welcome",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver_from_template(
      user.email,
      "welcome",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver_from_template(
      user.email,
      "password_reset",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver_from_template(
      user.email,
      "update_email",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver booking confirmation email.
  """
  def deliver_booking_confirmation(user, booking) do
    deliver_multipart(
      user.email,
      "Your booking is confirmed",
      "booking_confirmation",
      %{
        user: user,
        booking: booking,
        preheader: "#{booking.resource.name} - #{EmailView.format_date(booking.start_at)}"
      }
    )
  end

  @doc """
  Deliver contract confirmation email after successful payment.
  Contract should be preloaded with :resource and :user associations.
  """
  def deliver_contract_confirmation(user, contract) do
    deliver_from_template(
      user.email,
      "contract_confirmation",
      %{user: user, contract: contract}
    )
  end

  @doc """
  Deliver contract cancellation email.
  Contract should be preloaded with :resource association.
  """
  def deliver_contract_cancelled(user, contract) do
    deliver_from_template(
      user.email,
      "contract_cancelled",
      %{user: user, contract: contract}
    )
  end

  @doc """
  Deliver refund notification email.
  Contract should be preloaded with :resource association and have refund fields populated.
  """
  def deliver_refund_notification(user, contract) do
    deliver_from_template(
      user.email,
      "refund_notification",
      %{user: user, contract: contract}
    )
  end

  @doc """
  Deliver booking reminder email (24 hours before).
  Booking should be preloaded with :resource and :user associations.
  """
  def deliver_booking_reminder(user, booking) do
    deliver_from_template(
      user.email,
      "booking_reminder",
      %{user: user, booking: booking}
    )
  end

  @doc """
  Deliver contract expiration warning email.
  Contract should be preloaded with :resource and :user associations.
  """
  def deliver_contract_expiration_warning(user, contract, days_remaining) do
    # Add days_remaining to the contract map for template rendering
    contract_with_days = Map.put(contract, :days_remaining, days_remaining)

    deliver_from_template(
      user.email,
      "contract_expiration_warning",
      %{user: user, contract: contract_with_days}
    )
  end
end
