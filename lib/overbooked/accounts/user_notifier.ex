defmodule Overbooked.Accounts.UserNotifier do
  import Swoosh.Email

  alias Overbooked.Mailer
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

  # Delivers multipart email (HTML + text).
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

    deliver_multipart(
      email,
      "Welcome to Hatchbridge Rooms",
      "welcome",
      %{user: user, url: url, preheader: "Confirm your account to get started"}
    )
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver_multipart(
      user.email,
      "Welcome to Hatchbridge Rooms",
      "welcome",
      %{user: user, url: url, preheader: "Confirm your account to get started"}
    )
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver_multipart(
      user.email,
      "Reset your password",
      "password_reset",
      %{user: user, url: url, preheader: "Reset your Hatchbridge Rooms password"}
    )
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
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
    deliver_multipart(
      user.email,
      "Your contract is confirmed",
      "contract_confirmation",
      %{
        user: user,
        contract: contract,
        preheader: "#{contract.resource.name} - #{contract.duration_months} month contract confirmed"
      }
    )
  end

  @doc """
  Deliver contract cancellation email.
  Contract should be preloaded with :resource association.
  """
  def deliver_contract_cancelled(user, contract) do
    deliver_multipart(
      user.email,
      "Contract cancelled",
      "contract_cancelled",
      %{
        user: user,
        contract: contract,
        preheader: "Your #{contract.resource.name} contract has been cancelled"
      }
    )
  end
end
