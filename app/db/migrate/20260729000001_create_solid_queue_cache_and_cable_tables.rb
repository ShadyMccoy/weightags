class CreateSolidQueueCacheAndCableTables < ActiveRecord::Migration[8.1]
  # Solid Queue / Cache / Cable move into the **primary** database.
  #
  # Why: production previously declared `cache`, `queue`, and `cable` as separate
  # databases in config/database.yml, each with a `migrations_paths` directory
  # (db/queue_migrate, db/cache_migrate, db/cable_migrate) that does not exist in
  # this repo. Combined with `config.active_record.schema_format = :sql`
  # (application.rb — load-bearing for the audit-log trigger), `db:prepare` looks
  # for db/queue_structure.sql / db/cache_structure.sql / db/cable_structure.sql
  # to seed those databases. Those files do not exist either, so on a fresh
  # production database the solid_* tables were never created: the dispute clock
  # (recurring.yml) would not run, :solid_cache_store reads would raise, and
  # Turbo Stream broadcasts over solid_cable would fail. Development never caught
  # it because development uses :memory_store and the default async job adapter.
  #
  # A single database is the right shape for our deploy target (one managed
  # Postgres) and keeps one schema_migrations table and one structure.sql. The
  # table definitions below are transcribed from db/queue_schema.rb,
  # db/cache_schema.rb, and db/cable_schema.rb, which remain in the repo as the
  # upstream reference for what the generators produce.
  def change
    # --- Solid Cable (db/cable_schema.rb) --------------------------------------
    create_table :solid_cable_messages do |t|
      t.binary   :channel, limit: 1024, null: false
      t.binary   :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer  :channel_hash, limit: 8, null: false

      t.index :channel,      name: "index_solid_cable_messages_on_channel"
      t.index :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
      t.index :created_at,   name: "index_solid_cable_messages_on_created_at"
    end

    # --- Solid Cache (db/cache_schema.rb) --------------------------------------
    create_table :solid_cache_entries do |t|
      t.binary   :key, limit: 1024, null: false
      t.binary   :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer  :key_hash, limit: 8, null: false
      t.integer  :byte_size, limit: 4, null: false

      t.index :byte_size, name: "index_solid_cache_entries_on_byte_size"
      t.index %i[key_hash byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index :key_hash, name: "index_solid_cache_entries_on_key_hash", unique: true
    end

    # --- Solid Queue (db/queue_schema.rb) --------------------------------------
    create_table :solid_queue_jobs do |t|
      t.string   :queue_name, null: false
      t.string   :class_name, null: false
      t.text     :arguments
      t.integer  :priority, default: 0, null: false
      t.string   :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string   :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :active_job_id, name: "index_solid_queue_jobs_on_active_job_id"
      t.index :class_name,    name: "index_solid_queue_jobs_on_class_name"
      t.index :finished_at,   name: "index_solid_queue_jobs_on_finished_at"
      t.index %i[queue_name finished_at],   name: "index_solid_queue_jobs_for_filtering"
      t.index %i[scheduled_at finished_at], name: "index_solid_queue_jobs_for_alerting"
    end

    create_table :solid_queue_blocked_executions do |t|
      t.bigint   :job_id, null: false
      t.string   :queue_name, null: false
      t.integer  :priority, default: 0, null: false
      t.string   :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false

      t.index %i[concurrency_key priority job_id], name: "index_solid_queue_blocked_executions_for_release"
      t.index %i[expires_at concurrency_key], name: "index_solid_queue_blocked_executions_for_maintenance"
      t.index :job_id, name: "index_solid_queue_blocked_executions_on_job_id", unique: true
    end

    create_table :solid_queue_claimed_executions do |t|
      t.bigint   :job_id, null: false
      t.bigint   :process_id
      t.datetime :created_at, null: false

      t.index :job_id, name: "index_solid_queue_claimed_executions_on_job_id", unique: true
      t.index %i[process_id job_id], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
    end

    create_table :solid_queue_failed_executions do |t|
      t.bigint   :job_id, null: false
      t.text     :error
      t.datetime :created_at, null: false

      t.index :job_id, name: "index_solid_queue_failed_executions_on_job_id", unique: true
    end

    create_table :solid_queue_pauses do |t|
      t.string   :queue_name, null: false
      t.datetime :created_at, null: false

      t.index :queue_name, name: "index_solid_queue_pauses_on_queue_name", unique: true
    end

    create_table :solid_queue_processes do |t|
      t.string   :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint   :supervisor_id
      t.integer  :pid, null: false
      t.string   :hostname
      t.text     :metadata
      t.datetime :created_at, null: false
      t.string   :name, null: false

      t.index :last_heartbeat_at, name: "index_solid_queue_processes_on_last_heartbeat_at"
      t.index %i[name supervisor_id], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
      t.index :supervisor_id, name: "index_solid_queue_processes_on_supervisor_id"
    end

    create_table :solid_queue_ready_executions do |t|
      t.bigint   :job_id, null: false
      t.string   :queue_name, null: false
      t.integer  :priority, default: 0, null: false
      t.datetime :created_at, null: false

      t.index :job_id, name: "index_solid_queue_ready_executions_on_job_id", unique: true
      t.index %i[priority job_id], name: "index_solid_queue_poll_all"
      t.index %i[queue_name priority job_id], name: "index_solid_queue_poll_by_queue"
    end

    create_table :solid_queue_recurring_executions do |t|
      t.bigint   :job_id, null: false
      t.string   :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false

      t.index :job_id, name: "index_solid_queue_recurring_executions_on_job_id", unique: true
      t.index %i[task_key run_at], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
    end

    create_table :solid_queue_recurring_tasks do |t|
      t.string   :key, null: false
      t.string   :schedule, null: false
      t.string   :command, limit: 2048
      t.string   :class_name
      t.text     :arguments
      t.string   :queue_name
      t.integer  :priority, default: 0
      t.boolean  :static, default: true, null: false
      t.text     :description
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :key,    name: "index_solid_queue_recurring_tasks_on_key", unique: true
      t.index :static, name: "index_solid_queue_recurring_tasks_on_static"
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.bigint   :job_id, null: false
      t.string   :queue_name, null: false
      t.integer  :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false

      t.index :job_id, name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
      t.index %i[scheduled_at priority job_id], name: "index_solid_queue_dispatch_all"
    end

    create_table :solid_queue_semaphores do |t|
      t.string   :key, null: false
      t.integer  :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :expires_at, name: "index_solid_queue_semaphores_on_expires_at"
      t.index %i[key value], name: "index_solid_queue_semaphores_on_key_and_value"
      t.index :key, name: "index_solid_queue_semaphores_on_key", unique: true
    end

    add_foreign_key :solid_queue_blocked_executions,   :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions,   :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_failed_executions,    :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions,     :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end
end
