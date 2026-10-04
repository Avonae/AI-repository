---
name: ansible-playbook
description: 'Write Ansible playbooks, roles and inventory: FQCN modules, idempotent tasks, handlers, variables, ansible-lint. Use when creating or editing playbooks, roles, inventory, group_vars/host_vars or templates, or automating server setup with Ansible, even if the user does not say "playbook". For failing runs use ansible-debug; for turning shell scripts into tasks use ansible-convert.'
---

# Ansible Playbook Development

## Overview

Ansible playbooks declare desired system state rather than imperative commands. The core principle is idempotency: running a playbook multiple times produces the same result without unintended changes.

## Quick Reference

### Project Structure

```
project/
├── ansible.cfg          # Configuration
├── inventory            # Host definitions
├── group_vars/          # Group variables
├── host_vars/           # Host-specific vars
├── roles/               # Reusable roles
└── playbooks/           # Playbook files
```

### Essential ansible.cfg

```ini
[defaults]
inventory = ./inventory
roles_path = ./roles
stdout_callback = default
callback_result_format = yaml

[privilege_escalation]
become = True
become_method = sudo
```

### Module Patterns

| Operation | Module | Key Parameters |
|-----------|--------|----------------|
| Create directory | `ansible.builtin.file` | `state: directory`, `mode`, `owner` |
| Copy file | `ansible.builtin.copy` | `src`, `dest`, `mode` |
| Template | `ansible.builtin.template` | `src`, `dest`, variables in `.j2` |
| Install package | `ansible.builtin.package` | `name`, `state: present` |
| Manage service | `ansible.builtin.service` | `name`, `state`, `enabled` |
| Run command | `ansible.builtin.command` | `cmd`, register result, set `changed_when` |

### Variable Precedence (lowest to highest)

1. Role defaults (`defaults/main.yml`)
2. Group vars: inventory file, then `group_vars/all`, then `group_vars/<group>`
3. Host vars: inventory file, then `host_vars/<host>`
4. Host facts and cached `set_fact`
5. Play `vars`, then `vars_prompt`, then `vars_files`
6. Role vars (`vars/main.yml`)
7. Block vars, then task vars
8. `include_vars`
9. `set_fact` and `register`
10. Role and `include_role` params, then include params
11. Extra vars (`-e`) always win

In steps 2 and 3, `group_vars/` and `host_vars/` next to the playbook override the ones next to the inventory.

### Handlers

```yaml
tasks:
  - name: Update config
    ansible.builtin.template:
      src: app.conf.j2
      dest: /etc/app.conf
    notify: Restart app

handlers:
  - name: Restart app
    ansible.builtin.service:
      name: app
      state: restarted
```

### Error Handling

```yaml
- block:
    - name: Risky operation
      ansible.builtin.command: /opt/app/upgrade.sh
  rescue:
    - name: Handle failure
      ansible.builtin.debug:
        msg: "Upgrade failed, rolling back"
  always:
    - name: Cleanup
      ansible.builtin.file:
        path: /tmp/upgrade.lock
        state: absent
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using short module names | Always use FQCN: `ansible.builtin.copy` not `copy` |
| Hardcoded values | Extract to variables in `defaults/main.yml` |
| Missing `changed_when` on commands | Add `changed_when: "'created' in result.stdout"` |
| Forgetting handler flush | Use `meta: flush_handlers` when needed before dependent tasks |
| YAML indentation errors | Use 2 spaces, never tabs |
| Colon in unquoted string | Quote values containing `: ` |

## Verification Commands

```bash
ansible-playbook --syntax-check playbook.yml  # Check YAML
ansible-playbook --check playbook.yml         # Dry run
ansible-playbook --check --diff playbook.yml  # Show file changes
ansible-inventory --list                       # Verify inventory
ansible-inventory --host hostname             # Check host vars
ansible-lint playbook.yml                     # Best practices, FQCN, risky shell use
```

Run the playbook twice. The second run MUST report `changed=0`; any change means a task is not idempotent.
