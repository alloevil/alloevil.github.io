---
layout: single
title: 首页
---

## 训练概览
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
- 详情见：[俯卧撑记录](/workout/)

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
{% if range < 10 %}
  {% assign r1 = 1 %}{% assign r2 = 2 %}{% assign r3 = 3 %}{% assign r4 = 4 %}{% assign r5 = 5 %}{% assign r6 = 6 %}{% assign r7 = 7 %}{% assign r8 = 8 %}{% assign r9 = 9 %}
{% else %}
  {% assign step = range | divided_by: 10 %}
  {% assign r1 = step %}
  {% assign r2 = step | times: 2 %}
  {% assign r3 = step | times: 3 %}
  {% assign r4 = step | times: 4 %}
  {% assign r5 = step | times: 5 %}
  {% assign r6 = step | times: 6 %}
  {% assign r7 = step | times: 7 %}
  {% assign r8 = step | times: 8 %}
  {% assign r9 = step | times: 9 %}
{% endif %}
{% assign t1 = year_min | plus: r1 %}
{% assign t2 = year_min | plus: r2 %}
{% assign t3 = year_min | plus: r3 %}
{% assign t4 = year_min | plus: r4 %}
{% assign t5 = year_min | plus: r5 %}
{% assign t6 = year_min | plus: r6 %}
{% assign t7 = year_min | plus: r7 %}
{% assign t8 = year_min | plus: r8 %}
{% assign t9 = year_min | plus: r9 %}

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
{% assign heat_w = 12 | times: month_width %}
{% assign gaps_w = 11 | times: month_gap %}
{% assign heat_w = heat_w | plus: gaps_w | plus: heat_left | plus: heat_right %}
{% assign heat_h = 7 | times: heat_step %}
<div class="heatmap-scroll">
  <svg width="{{ heat_w }}" height="{{ heat_h | plus: heat_top | plus: heat_bottom | plus: 24 }}" viewBox="0 0 {{ heat_w }} {{ heat_h | plus: heat_top | plus: heat_bottom | plus: 24 }}" xmlns="http://www.w3.org/2000/svg">
    <g transform="translate(0, {{ heat_top }})">
      {% for m in (1..12) %}
      {% assign mm = m %}{% if m < 10 %}{% assign mm = "0" | append: m %}{% endif %}
      {% assign month_str = year | append: "-" | append: mm %}
      {% assign first_day = month_str | append: "-01" %}
      {% assign first_w = first_day | date: "%w" | plus: 0 %}
      {% assign m_index = m | minus: 1 %}
      {% assign mw = month_width | times: m_index %}
      {% assign mg = month_gap | times: m_index %}
      {% assign month_offset = heat_left | plus: mw | plus: mg %}
      {% for i in (1..31) %}
        {% assign dd = i %}{% if i < 10 %}{% assign dd = "0" | append: i %}{% endif %}
        {% assign day_date = month_str | append: "-" | append: dd %}
        {% assign d_m = day_date | date: "%Y-%m" %}
        {% if d_m == month_str %}
          {% assign dow = day_date | date: "%w" | plus: 0 %}
          {% assign col_base = i | minus: 1 | plus: first_w %}
          {% assign col = col_base | divided_by: 7 %}
          {% assign col_px = col | times: heat_step %}
          {% assign x = month_offset | plus: col_px %}
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
          {% if day_total > 0 and day_total <= t1 %}{% assign fill = "#eef8d6" %}{% endif %}
          {% if day_total > t1 and day_total <= t2 %}{% assign fill = "#e6f5c9" %}{% endif %}
          {% if day_total > t2 and day_total <= t3 %}{% assign fill = "#d6efaa" %}{% endif %}
          {% if day_total > t3 and day_total <= t4 %}{% assign fill = "#c6e48b" %}{% endif %}
          {% if day_total > t4 and day_total <= t5 %}{% assign fill = "#b2dc78" %}{% endif %}
          {% if day_total > t5 and day_total <= t6 %}{% assign fill = "#a5d76e" %}{% endif %}
          {% if day_total > t6 and day_total <= t7 %}{% assign fill = "#8ac55e" %}{% endif %}
          {% if day_total > t7 and day_total <= t8 %}{% assign fill = "#66b34f" %}{% endif %}
          {% if day_total > t8 and day_total <= t9 %}{% assign fill = "#2ca244" %}{% endif %}
          {% if day_total > t9 %}{% assign fill = "#196127" %}{% endif %}
          <rect x="{{ x }}" y="{{ y }}" width="{{ heat_box }}" height="{{ heat_box }}" rx="2" ry="2" fill="{{ fill }}"><title>{{ day_date }}: {{ day_total }} 次</title></rect>
        {% endif %}
      {% endfor %}
      {% endfor %}
      {% assign label_y = heat_h | plus: 16 %}
      {% for m in (1..12) %}
        {% assign m_index = m | minus: 1 %}
        {% assign mw = month_width | times: m_index %}
        {% assign mg = month_gap | times: m_index %}
        {% assign month_offset = heat_left | plus: mw | plus: mg %}
        {% assign half_month = month_width | divided_by: 2 %}
        {% assign lx = month_offset | plus: half_month %}
        <text class="month-label" x="{{ lx }}" y="{{ label_y }}" text-anchor="middle">{{ m }}</text>
      {% endfor %}
    </g>
  </svg>
</div>


## 文章
{% assign posts_list = site.posts | slice: 0, 10 %}
<ul>
{% for p in posts_list %}
  <li><a href="{{ p.url }}">{{ p.title }}</a> <small>· {{ p.date | date: "%Y-%m-%d" }}</small></li>
{% endfor %}
</ul>

<hr class="section-sep" />

## 文章
{% assign posts_list = site.posts | slice: 0, 10 %}
<ul>
{% for p in posts_list %}
  <li><a href="{{ p.url }}">{{ p.title }}</a> <small>· {{ p.date | date: "%Y-%m-%d" }}</small></li>
{% endfor %}
</ul>

更多文章见：[文章](/blog/)
