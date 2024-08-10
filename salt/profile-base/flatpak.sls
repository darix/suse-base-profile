{%- if "flatpak" in pillar %}
flatpak-packages:
  pkg.latest:
    - pkgs:
      - flatpak
      - flatpak-builder

  {%- set registered_repositories = [] %}
  {%- if "repositories" in pillar.flatpak %}

    {%- for repository_name, repository_data in pillar.flatpak.repositories.items() %}

    {%- do registered_repositories.append(repository_name) %}

flatpak-{{ repository_name }}:
  cmd.run:
    - name: flatpak remote-add --if-not-exists {{ repository_name }} {{ repository_data['url'] }}
    - onchanges:
      - flatpak-packages
    - require:
      - flatpak-packages
    {%- endfor %}
  {%- endif %}

  {%- if "apps" in pillar.flatpak and registered_repositories|length > 0 %}
    {%- for app_name in pillar.flatpak %}

flatpak-app-{{ app_name }}:
  cmd.run:
  - name: flatpak install {{ app_name }}
  - require:
    {%- for repository in registered_repositories %}
    - {{ repository }}
    {%- endfor %}

    {%- endfor %}
  {%- endif %}

{%- endif %}
