defmodule Overbooked.Schedule.RecurringExpander do
  @moduledoc """
  Service module that expands a recurring rule into booking dates.
  
  Uses Timex to calculate occurrence dates based on pattern type.
  """

  alias Overbooked.Schedule.RecurringRule

  @doc """
  Expands a recurring rule into a list of booking attribute maps.
  
  Each map contains:
  - `:start_at` - UTC datetime for booking start
  - `:end_at` - UTC datetime for booking end
  
  ## Examples
  
      expand_rule(%RecurringRule{
        pattern: "weekly",
        interval: 1,
        days_of_week: [1, 3, 5],
        start_date: ~D[2024-01-01],
        end_date: ~D[2024-01-31],
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00]
      })
      # Returns list of %{start_at: ~U[...], end_at: ~U[...]} maps
  """
  def expand_rule(%RecurringRule{} = rule) do
    occurrences = generate_occurrences(rule)
    
    Enum.map(occurrences, fn date ->
      start_at = to_utc_datetime(date, rule.start_time)
      end_at = to_utc_datetime(date, rule.end_time)
      
      %{start_at: start_at, end_at: end_at}
    end)
  end

  @doc """
  Generates just the dates (without times) for a recurring rule.
  Useful for preview functionality.
  """
  def generate_occurrences(%RecurringRule{} = rule) do
    case rule.pattern do
      "daily" -> generate_daily(rule)
      "weekly" -> generate_weekly(rule)
      "biweekly" -> generate_biweekly(rule)
      "monthly" -> generate_monthly(rule)
    end
  end

  # Daily pattern: every N days
  defp generate_daily(%RecurringRule{} = rule) do
    generate_dates(
      rule.start_date,
      rule.end_date,
      rule.max_occurrences,
      fn date -> Timex.shift(date, days: rule.interval) end,
      fn _date -> true end
    )
  end

  # Weekly pattern: specific days of week, every N weeks
  defp generate_weekly(%RecurringRule{} = rule) do
    days_set = MapSet.new(rule.days_of_week)
    
    generate_dates(
      rule.start_date,
      rule.end_date,
      rule.max_occurrences,
      fn date -> Timex.shift(date, days: 1) end,
      fn date ->
        day_of_week = Timex.weekday(date, :monday)
        week_num = div(Timex.diff(date, rule.start_date, :days), 7)
        
        MapSet.member?(days_set, day_of_week) and rem(week_num, rule.interval) == 0
      end
    )
  end

  # Biweekly pattern: specific days of week, every 2 weeks
  defp generate_biweekly(%RecurringRule{} = rule) do
    # Biweekly is just weekly with interval 2
    rule_with_interval = %{rule | interval: 2}
    generate_weekly(rule_with_interval)
  end

  # Monthly pattern: same day of month, every N months
  defp generate_monthly(%RecurringRule{} = rule) do
    day_of_month = rule.start_date.day
    
    generate_dates(
      rule.start_date,
      rule.end_date,
      rule.max_occurrences,
      fn date -> 
        next_month = Timex.shift(date, months: rule.interval)
        # Handle months with fewer days (e.g., Jan 31 -> Feb 28)
        max_day = Timex.days_in_month(next_month)
        target_day = min(day_of_month, max_day)
        %{next_month | day: target_day}
      end,
      fn _date -> true end
    )
  end

  # Generic date generator with filter and next_date functions
  defp generate_dates(start_date, end_date, max_occurrences, next_fn, filter_fn) do
    Stream.unfold(start_date, fn
      nil -> nil
      current_date ->
        cond do
          end_date && Date.compare(current_date, end_date) == :gt ->
            nil
          true ->
            next = next_fn.(current_date)
            {current_date, next}
        end
    end)
    |> Stream.filter(filter_fn)
    |> limit_occurrences(max_occurrences)
    |> Enum.to_list()
  end

  defp limit_occurrences(stream, nil), do: stream
  defp limit_occurrences(stream, max), do: Stream.take(stream, max)

  # Convert a date and time to UTC datetime
  defp to_utc_datetime(date, time) do
    {:ok, naive} = NaiveDateTime.new(date, time)
    DateTime.from_naive!(naive, "Etc/UTC")
  end
end
