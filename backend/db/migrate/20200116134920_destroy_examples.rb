class DestroyExamples < ActiveRecord::Migration[6.0]
  def change
    drop_table :examples
  end
end
