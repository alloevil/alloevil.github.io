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

## 博客
{% assign posts_list = site.posts | slice: 0, 10 %}
<ul>
{% for p in posts_list %}
  <li><a href="{{ p.url }}">{{ p.title }}</a> <small>· {{ p.date | date: "%Y-%m-%d" }}</small></li>
{% endfor %}
</ul>

更多文章见：[博客](/blog/)
