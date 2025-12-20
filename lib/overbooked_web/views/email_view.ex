defmodule OverbookedWeb.EmailView do
  use OverbookedWeb, :view

  @doc """
  Renders an email template with common assigns like logo_url, base_url, etc.
  """
  def render_email(template, assigns) do
    base_assigns = %{
      logo_url: "#{OverbookedWeb.Endpoint.url()}/images/hatchbridge-logo.svg",
      base_url: OverbookedWeb.Endpoint.url(),
      current_year: Date.utc_today().year
    }

    full_assigns = Map.merge(base_assigns, assigns)

    render(template, full_assigns)
  end

  @doc """
  Formats a date for email display.
  """
  def format_date(datetime) do
    {:ok, str} = Timex.format(datetime, "{Mfull} {D}, {YYYY}")
    str
  end

  @doc """
  Formats a time range for email display.
  """
  def format_time_range(booking) do
    {:ok, start_time} = Timex.format(booking.start_at, "{h12}:{m} {AM}")
    {:ok, end_time} = Timex.format(booking.end_at, "{h12}:{m} {AM}")
    "#{start_time} - #{end_time}"
  end
end
