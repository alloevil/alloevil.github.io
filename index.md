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
{% assign gap = 8 %}
{% assign step = bar_w | plus: gap %}
{% assign chart_w = days | times: step | plus: 40 %}
<svg width="{{ chart_w }}" height="{{ chart_h | plus: 40 }}" viewBox="0 0 {{ chart_w }} {{ chart_h | plus: 40 }}" xmlns="http://www.w3.org/2000/svg">
  <line x1="20" y1="{{ chart_h }}" x2="{{ chart_w | minus: 20 }}" y2="{{ chart_h }}" stroke="#999" stroke-width="1"/>
  <line x1="20" y1="0" x2="20" y2="{{ chart_h }}" stroke="#999" stroke-width="1"/>
  {% assign tick_step = max_total | divided_by: 4 %}{% if tick_step == 0 %}{% assign tick_step = 1 %}{% endif %}
  {% for i in (0..4) %}
    {% if i == 4 %}{% assign val = max_total %}{% else %}{% assign val = i | times: tick_step %}{% endif %}
    {% assign h = val | times: chart_h | divided_by: max_total %}
    {% assign y = chart_h | minus: h %}
    <line x1="20" y1="{{ y }}" x2="{{ chart_w | minus: 20 }}" y2="{{ y }}" stroke="#eee" stroke-width="1"/>
    <text x="16" y="{{ y | plus: 4 }}" font-size="10" text-anchor="end">{{ val }}</text>
  {% endfor %}
  {% assign x = 20 %}
  {% for e in entries %}
    {% assign d = e.date | slice: 0, 7 %}
    {% if d == month %}
      {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
      {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
      {% assign day_total = am_total | plus: pm_total %}
      {% assign h = day_total | times: chart_h | divided_by: max_total %}
      {% assign y = chart_h | minus: h %}
      <rect x="{{ x }}" y="{{ y }}" width="{{ bar_w }}" height="{{ h }}" fill="#4caf50" />
      <text x="{{ x | plus: 10 }}" y="{{ chart_h | plus: 14 }}" font-size="10" text-anchor="middle">{{ e.date | slice: -2, 2 }}</text>
      <text x="{{ x | plus: 10 }}" y="{{ y | minus: 4 }}" font-size="10" text-anchor="middle">{{ day_total }}</text>
      {% assign x = x | plus: step %}
    {% endif %}
  {% endfor %}
</svg>

## 文章
{% assign posts_list = site.posts | slice: 0, 10 %}
<ul>
{% for p in posts_list %}
  <li><a href="{{ p.url }}">{{ p.title }}</a> <small>· {{ p.date | date: "%Y-%m-%d" }}</small></li>
{% endfor %}
</ul>

更多文章见：[文章](/blog/)
