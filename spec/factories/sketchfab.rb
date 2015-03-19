FactoryGirl.define do
  factory :sketchfab do
    bbcode <<-eos
      [sketchfab]55ea0aed9bfd462593f006ea8c4aade0[/sketchfab]
      [url=https://sketchfab.com/models/55ea0aed9bfd462593f006ea8c4aade0]The Lion of Mosul[/url] by [url=https://sketchfab.com/neshmi]neshmi[/url] on [url=https://sketchfab.com]Sketchfab[/url]
    eos
    trait :with_artefact do
      artefact
    end
  end
end