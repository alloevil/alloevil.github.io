---
layout: single
title: 俯卧撑记录
permalink: /workout/
---

{% assign month = site.time | date: "%Y-%m" %}
{% assign entries = site.data.workouts %}

{% assign days = 0 %}
{% assign month_total = 0 %}
{% assign am_month = 0 %}
{% assign pm_month = 0 %}

{% for e in entries %}
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

### 本月折线图
{% assign max_total = 0 %}
{% for e in entries %}
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
{% for e in entries %}
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
  {% for e in entries %}
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
  <text x="{{ left_pad | plus: chart_w | minus: left_pad | minus: right_pad | divided_by: 2 }}" y="{{ chart_h | plus: 44 }}" font-size="11" text-anchor="middle">日期</text>
  <text x="{{ left_pad | minus: 22 }}" y="{{ chart_h | divided_by: 2 }}" font-size="11" text-anchor="middle" transform="rotate(-90 {{ left_pad | minus: 22 }}, {{ chart_h | divided_by: 2 }})">次数</text>
</svg>

## 明细
{% for e in entries %}
  {% assign d = e.date | slice: 0, 7 %}
  {% if d == month %}
    {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
    {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
- {{ e.date }}{% if e.am %} · 早：{{ am_total }} 次（{{ e.am | join: ", " }}）{% endif %}{% if e.pm %} · 晚：{{ pm_total }} 次（{{ e.pm | join: ", " }}）{% endif %}{% if e.notes %} · {{ e.notes }}{% endif %}
  {% endif %}
{% endfor %}
