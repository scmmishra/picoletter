FactoryBot.define do
  factory(:user) do
    active {true}
    bio {nil}
    email {"neo@example.com"}
    is_superadmin {true}  
    name {"Neo Anderson"}
  end
end
