---
layout: single
title: 首页
---

## 训练概览
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
- 详情见：[俯卧撑记录](/workout/)

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

### 本月图表
{% assign chart_h = 160 %}
{% assign bar_w = 20 %}
{% assign half_bar = bar_w | divided_by: 2 %}
{% assign gap = 8 %}
{% assign step = bar_w | plus: gap %}
{% assign left_pad = 32 %}
{% assign right_pad = 24 %}
{% assign top_pad = 36 %}
{% assign bottom_pad = 32 %}
{% assign step_total = days | times: step %}
{% assign chart_w = left_pad | plus: step_total | plus: right_pad %}
{% assign half_step_total = step_total | divided_by: 2 %}
<svg width="{{ chart_w }}" height="{{ chart_h | plus: top_pad | plus: bottom_pad }}" viewBox="0 0 {{ chart_w }} {{ chart_h | plus: top_pad | plus: bottom_pad }}" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(0, {{ top_pad }})">
    <line class="axis axis--x" x1="{{ left_pad }}" y1="{{ chart_h }}" x2="{{ chart_w | minus: right_pad }}" y2="{{ chart_h }}" stroke="#999" stroke-width="1"/>
    <line x1="{{ left_pad }}" y1="0" x2="{{ left_pad }}" y2="{{ chart_h }}" stroke="#999" stroke-width="1"/>
  {% assign tick_step = max_total | divided_by: 4 %}{% if tick_step == 0 %}{% assign tick_step = 1 %}{% endif %}
  {% for i in (0..4) %}
    {% if i == 4 %}{% assign val = max_total %}{% else %}{% assign val = i | times: tick_step %}{% endif %}
    {% assign h = val | times: chart_h | divided_by: max_total %}
    {% assign y = chart_h | minus: h %}
    <line class="grid" x1="{{ left_pad }}" y1="{{ y }}" x2="{{ chart_w | minus: right_pad }}" y2="{{ y }}" />
    <text class="tick-label" x="{{ left_pad | minus: 6 }}" y="{{ y | plus: 4 }}" text-anchor="end">{{ val }}</text>
  {% endfor %}
  <text x="{{ left_pad | minus: 22 }}" y="{{ chart_h | divided_by: 2 }}" font-size="11" text-anchor="middle" transform="rotate(-90 {{ left_pad | minus: 22 }}, {{ chart_h | divided_by: 2 }})">次数</text>
  {% assign x = left_pad %}
  {% for e in entries %}
    {% assign d = e.date | slice: 0, 7 %}
    {% if d == month %}
      {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
      {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
      {% assign day_total = am_total | plus: pm_total %}
      {% assign h = day_total | times: chart_h | divided_by: max_total %}
      {% assign y = chart_h | minus: h %}
      <rect class="bar" rx="4" ry="4" x="{{ x }}" y="{{ y }}" width="{{ bar_w }}" height="{{ h }}" />
      <text class="bar-label" x="{{ x | plus: half_bar }}" y="{{ chart_h | plus: 14 }}" text-anchor="middle">{{ e.date | slice: -2, 2 }}</text>
      <text class="value-label" x="{{ x | plus: half_bar }}" y="{{ y | minus: 8 }}" text-anchor="middle">{{ day_total }}</text>
      {% assign x = x | plus: step %}
    {% endif %}
  {% endfor %}
  <text x="{{ left_pad | plus: half_step_total }}" y="{{ chart_h | plus: 28 }}" font-size="11" text-anchor="middle">日期</text>
  </g>
</svg>

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
