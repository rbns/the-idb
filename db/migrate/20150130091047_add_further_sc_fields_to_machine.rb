class AddFurtherScFieldsToMachine < ActiveRecord::Migration[4.2]
  def change
    add_column :machines, :business_criticality, :string
    add_column :machines, :business_notification, :string
  end
end
