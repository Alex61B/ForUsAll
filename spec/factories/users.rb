FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name  { "User" }
    password   { "password123" }
    role       { :employee }

    trait :manager do
      role { :manager }
    end

    trait :admin do
      role { :admin }
    end

    trait :with_department do
      association :department
    end

    trait :with_manager do
      association :manager, factory: [ :user, :manager ]
    end
  end
end
