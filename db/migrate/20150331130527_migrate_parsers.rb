class MigrateParsers < ActiveRecord::Migration
  def change
    Canteen.transaction do
      Canteen.all.each do |c|
        next unless c.url.present?
        parserName = c.url[0..c.url.rindex('/')-1]
        p = Parser.find_or_create_by!(name: parserName, user_id: c.user_id)
        s = Source.create! parser: p,
                           name: c.url[(c.url.rindex('/')+1)..400],
                           canteen: c
        Feed.create! name: 'full',
                     source: s,
                     url: c.url,
                     schedule: '0 8 * * *',
                     retry: '60 6',
                     priority: 0
        if c.today_url.present?
          Feed.create! name: 'today',
                       source: s,
                       url: c.today_url,
                       schedule: '0 8-14 * * *',
                       priority: 10
        end
        c.url = nil
        c.today_url = nil
        c.save!
      end
    end
  end
end