---
layout: single
title: 俯卧撑记录
permalink: /workout/
---

{% assign month = site.time | date: "%Y-%m" %}
{% assign entries = site.data.workouts %}
{% assign entries_sorted = entries | sort: "date" %}

{% assign days = 0 %}
{% assign month_total = 0 %}
{% assign am_month = 0 %}
{% assign pm_month = 0 %}

{% for e in entries_sorted %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign days = days | plus: 1 %}
    {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
    {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
    {% assign day_total = am_total | plus: pm_total %}
    {% assign month_total = month_total | plus: day_total %}
    {% assign am_month = am_month | plus: am_total %}
    {% assign pm_month = pm_month | plus: pm_total %}
  {% endif %}
{% endfor %}

- 本月打卡天数：{{ days }}
- 本月总俯卧撑：{{ month_total }} 次（早：{{ am_month }} · 晚：{{ pm_month }}）

### 全年热力图
{% assign year = site.time | date: "%Y" %}
{% assign year_max = 0 %}{% assign year_min = 0 %}
{% for e in entries_sorted %}
  {% assign y = e.date | slice: 0, 4 %}
  {% if y == year %}
    {% assign am_t = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_t = am_t | plus: r %}{% endfor %}{% endif %}
    {% assign pm_t = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_t = pm_t | plus: r %}{% endfor %}{% endif %}
    {% assign day_t = am_t | plus: pm_t %}
    {% if day_t > year_max %}{% assign year_max = day_t %}{% endif %}
    {% if year_min == 0 and day_t > 0 %}{% assign year_min = day_t %}{% endif %}
    {% if day_t > 0 and day_t < year_min %}{% assign year_min = day_t %}{% endif %}
  {% endif %}
{% endfor %}
{% if year_max == 0 %}{% assign year_max = 1 %}{% endif %}
{% if year_min == 0 %}{% assign year_min = 1 %}{% endif %}
{% assign range = year_max | minus: year_min %}
{% if range < 5 %}
  {% assign r1 = 1 %}{% assign r2 = 2 %}{% assign r3 = 3 %}{% assign r4 = 4 %}
{% else %}
  {% assign r1 = range | divided_by: 5 %}
  {% assign r2 = r1 | times: 2 %}
  {% assign r3 = r1 | times: 3 %}
  {% assign r4 = r1 | times: 4 %}
{% endif %}
{% assign t1 = year_min | plus: r1 %}
{% assign t2 = year_min | plus: r2 %}
{% assign t3 = year_min | plus: r3 %}
{% assign t4 = year_min | plus: r4 %}

{% assign heat_box = 12 %}
{% assign heat_gap = 2 %}
{% assign heat_step = heat_box | plus: heat_gap %}
{% assign month_weeks = 6 %}
{% assign month_gap = 8 %}
{% assign heat_left = 32 %}
{% assign heat_right = 24 %}
{% assign heat_top = 10 %}
{% assign heat_bottom = 10 %}
{% assign month_width = month_weeks | times: heat_step %}
{% assign heat_w = heat_left | plus: 12 | times: month_width | plus: 11 | times: month_gap | plus: heat_right %}
{% assign heat_h = 7 | times: heat_step %}
<svg width="{{ heat_w }}" height="{{ heat_h | plus: heat_top | plus: heat_bottom }}" viewBox="0 0 {{ heat_w }} {{ heat_h | plus: heat_top | plus: heat_bottom }}" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(0, {{ heat_top }})">
    {% for m in (1..12) %}
      {% assign mm = m %}{% if m < 10 %}{% assign mm = "0" | append: m %}{% endif %}
      {% assign month_str = year | append: "-" | append: mm %}
      {% assign first_day = month_str | append: "-01" %}
      {% assign first_w = first_day | date: "%w" | plus: 0 %}
      {% assign m_index = m | minus: 1 %}
      {% assign month_offset = heat_left | plus: month_width | times: m_index | plus: month_gap | times: m_index %}
      {% for i in (1..31) %}
        {% assign dd = i %}{% if i < 10 %}{% assign dd = "0" | append: i %}{% endif %}
        {% assign day_date = month_str | append: "-" | append: dd %}
        {% assign d_m = day_date | date: "%Y-%m" %}
        {% if d_m == month_str %}
          {% assign dow = day_date | date: "%w" | plus: 0 %}
          {% assign col_base = i | minus: 1 | plus: first_w %}
          {% assign col = col_base | divided_by: 7 %}
          {% assign x = month_offset | plus: col | times: heat_step %}
          {% assign y = dow | times: heat_step %}
          {% assign day_total = 0 %}
          {% for e in entries_sorted %}
            {% if e.date == day_date %}
              {% assign am_t = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_t = am_t | plus: r %}{% endfor %}{% endif %}
              {% assign pm_t = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_t = pm_t | plus: r %}{% endfor %}{% endif %}
              {% assign day_total = am_t | plus: pm_t %}
            {% endif %}
          {% endfor %}
          {% assign fill = "#ebedf0" %}
          {% if day_total > 0 and day_total <= t1 %}{% assign fill = "#c6e48b" %}{% endif %}
          {% if day_total > t1 and day_total <= t2 %}{% assign fill = "#a5d76e" %}{% endif %}
          {% if day_total > t2 and day_total <= t3 %}{% assign fill = "#7bc96f" %}{% endif %}
          {% if day_total > t3 and day_total <= t4 %}{% assign fill = "#239a3b" %}{% endif %}
          {% if day_total > t4 %}{% assign fill = "#196127" %}{% endif %}
          <rect x="{{ x }}" y="{{ y }}" width="{{ heat_box }}" height="{{ heat_box }}" rx="2" ry="2" fill="{{ fill }}"><title>{{ day_date }}: {{ day_total }} 次</title></rect>
        {% endif %}
      {% endfor %}
    {% endfor %}
  </g>
</svg>

{% assign first_day = month | append: "-01" %}
{% assign first_w = first_day | date: "%w" | plus: 0 %}
{% assign heat_box = 12 %}
{% assign heat_gap = 2 %}
{% assign heat_step = heat_box | plus: heat_gap %}
{% assign heat_weeks = 6 %}
{% assign heat_left = 32 %}
{% assign heat_right = 24 %}
{% assign heat_top = 10 %}
{% assign heat_bottom = 10 %}
{% assign heat_w = heat_left | plus: heat_weeks | times: heat_step | plus: heat_right %}
{% assign heat_h = 7 | times: heat_step %}
{% assign max_total = 0 %}
{% for e in entries_sorted %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign am_t = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_t = am_t | plus: r %}{% endfor %}{% endif %}
    {% assign pm_t = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_t = pm_t | plus: r %}{% endfor %}{% endif %}
    {% assign day_t = am_t | plus: pm_t %}
    {% if day_t > max_total %}{% assign max_total = day_t %}{% endif %}
  {% endif %}
{% endfor %}
{% if max_total == 0 %}{% assign max_total = 1 %}{% endif %}
{% assign min_total = max_total %}
{% for e in entries_sorted %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign am_t = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_t = am_t | plus: r %}{% endfor %}{% endif %}
    {% assign pm_t = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_t = pm_t | plus: r %}{% endfor %}{% endif %}
    {% assign day_t = am_t | plus: pm_t %}
    {% if day_t > 0 and day_t < min_total %}{% assign min_total = day_t %}{% endif %}
  {% endif %}
{% endfor %}
{% if min_total == 0 %}{% assign min_total = 1 %}{% endif %}
{% assign range = max_total | minus: min_total %}
{% if range < 5 %}
  {% assign r1 = 1 %}{% assign r2 = 2 %}{% assign r3 = 3 %}{% assign r4 = 4 %}
{% else %}
  {% assign r1 = range | divided_by: 5 %}
  {% assign r2 = r1 | times: 2 %}
  {% assign r3 = r1 | times: 3 %}
  {% assign r4 = r1 | times: 4 %}
{% endif %}
{% assign t1 = min_total | plus: r1 %}
{% assign t2 = min_total | plus: r2 %}
{% assign t3 = min_total | plus: r3 %}
{% assign t4 = min_total | plus: r4 %}
<svg width="{{ heat_w }}" height="{{ heat_h | plus: heat_top | plus: heat_bottom }}" viewBox="0 0 {{ heat_w }} {{ heat_h | plus: heat_top | plus: heat_bottom }}" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(0, {{ heat_top }})">
    {% for i in (1..31) %}
      {% assign dd = i %}{% if i < 10 %}{% assign dd = "0" | append: i %}{% endif %}
      {% assign day_date = month | append: "-" | append: dd %}
      {% assign d_m = day_date | date: "%Y-%m" %}
      {% if d_m == month %}
        {% assign dow = day_date | date: "%w" | plus: 0 %}
        {% assign col_base = i | minus: 1 | plus: first_w %}
        {% assign col = col_base | divided_by: 7 %}
        {% assign x = col | times: heat_step | plus: heat_left %}
        {% assign y = dow | times: heat_step %}
        {% assign day_total = 0 %}
        {% for e in entries_sorted %}
          {% if e.date == day_date %}
            {% assign am_t = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_t = am_t | plus: r %}{% endfor %}{% endif %}
            {% assign pm_t = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_t = pm_t | plus: r %}{% endfor %}{% endif %}
            {% assign day_total = am_t | plus: pm_t %}
          {% endif %}
        {% endfor %}
        {% assign fill = "#ebedf0" %}
        {% if day_total > 0 and day_total <= t1 %}{% assign fill = "#c6e48b" %}{% endif %}
        {% if day_total > t1 and day_total <= t2 %}{% assign fill = "#a5d76e" %}{% endif %}
        {% if day_total > t2 and day_total <= t3 %}{% assign fill = "#7bc96f" %}{% endif %}
        {% if day_total > t3 and day_total <= t4 %}{% assign fill = "#239a3b" %}{% endif %}
        {% if day_total > t4 %}{% assign fill = "#196127" %}{% endif %}
        <rect x="{{ x }}" y="{{ y }}" width="{{ heat_box }}" height="{{ heat_box }}" rx="2" ry="2" fill="{{ fill }}"><title>{{ day_date }}: {{ day_total }} 次</title></rect>
      {% endif %}
    {% endfor %}
  </g>
</svg>

### 本月折线图
{% assign max_total = 0 %}
{% for e in entries_sorted %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
    {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
    {% assign day_total = am_total | plus: pm_total %}
    {% if day_total > max_total %}{% assign max_total = day_total %}{% endif %}
  {% endif %}
{% endfor %}
{% if max_total == 0 %}{% assign max_total = 1 %}{% endif %}

{% assign chart_h = 160 %}
{% assign step = 28 %}
{% assign left_pad = 32 %}{% assign right_pad = 24 %}{% assign top_pad = 36 %}{% assign bottom_pad = 48 %}
{% assign chart_w = days | times: step | plus: left_pad | plus: right_pad %}
{% assign points = "" %}
{% assign x = left_pad %}
{% assign label_offset = 10 %}
{% assign min_label_y = 10 %}
{% for e in entries_sorted %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
    {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
    {% assign day_total = am_total | plus: pm_total %}
    {% assign h = day_total | times: chart_h | divided_by: max_total %}
    {% assign y = chart_h | minus: h %}
    {% assign points = points | append: x | append: "," | append: y | append: " " %}
    {% assign x = x | plus: step %}
  {% endif %}
{% endfor %}

{% assign left_pad = 32 %}{% assign right_pad = 24 %}{% assign top_pad = 36 %}{% assign bottom_pad = 80 %}
<svg width="{{ chart_w }}" height="{{ chart_h | plus: top_pad | plus: bottom_pad }}" viewBox="0 0 {{ chart_w }} {{ chart_h | plus: top_pad | plus: bottom_pad }}" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(0, {{ top_pad }})">
  <line class="axis axis--x" x1="{{ left_pad }}" y1="{{ chart_h }}" x2="{{ chart_w | minus: right_pad }}" y2="{{ chart_h }}" />
  {% assign tick_step = max_total | divided_by: 4 %}{% if tick_step == 0 %}{% assign tick_step = 1 %}{% endif %}
  {% for i in (0..4) %}
    {% if i == 4 %}{% assign val = max_total %}{% else %}{% assign val = i | times: tick_step %}{% endif %}
    {% assign h = val | times: chart_h | divided_by: max_total %}
    {% assign y = chart_h | minus: h %}
    <line x1="{{ left_pad }}" y1="{{ y }}" x2="{{ chart_w | minus: right_pad }}" y2="{{ y }}" stroke="#eee" stroke-width="1"/>
    <text x="{{ left_pad | minus: 4 }}" y="{{ y | plus: 4 }}" font-size="10" text-anchor="end">{{ val }}</text>
  {% endfor %}
  <polyline class="line" fill="none" points="{{ points | strip }}" />
  {% assign x = left_pad %}
  {% for e in entries_sorted %}
    {% assign d = e.date | slice: 0, 7 %}
    {% if d == month %}
      {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
      {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
      {% assign day_total = am_total | plus: pm_total %}
      {% assign h = day_total | times: chart_h | divided_by: max_total %}
      {% assign y = chart_h | minus: h %}
      <circle class="dot" cx="{{ x }}" cy="{{ y }}" r="3" />
      <text class="bar-label" x="{{ x }}" y="{{ chart_h | plus: 22 }}" text-anchor="middle" transform="rotate(30 {{ x }}, {{ chart_h | plus: 22 }})">{{ e.date | slice: -2, 2 }}</text>
      {% assign label_y = y | minus: 12 %}{% if label_y < 8 %}{% assign label_y = 8 %}{% endif %}
      <text class="value-label" x="{{ x }}" y="{{ label_y }}" text-anchor="middle">{{ day_total }}</text>
      {% assign x = x | plus: step %}
    {% endif %}
  {% endfor %}
  <text x="{{ left_pad | plus: chart_w | minus: left_pad | minus: right_pad | divided_by: 2 }}" y="{{ chart_h | plus: 44 }}" font-size="11" text-anchor="middle">Date</text>
  <text x="{{ left_pad | minus: 22 }}" y="{{ chart_h | divided_by: 2 }}" font-size="11" text-anchor="middle" transform="rotate(-90 {{ left_pad | minus: 22 }}, {{ chart_h | divided_by: 2 }})">Count</text>
</svg>

## 明细
{% for e in entries_sorted %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
    {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
- {{ e.date }}{% if e.am %} · 早：{{ am_total }} 次（{{ e.am | join: ", " }}）{% endif %}{% if e.pm %} · 晚：{{ pm_total }} 次（{{ e.pm | join: ", " }}）{% endif %}{% if e.notes %} · {{ e.notes }}{% endif %}
  {% endif %}
{% endfor %}
