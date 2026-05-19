FactoryBot.define do
  factory :approval do
    association :time_off_request
    association :approver, factory: [ :user, :manager ]
    decision { :approved }
    notes    { "Approved." }
  end
end
