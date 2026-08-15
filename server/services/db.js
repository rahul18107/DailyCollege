const { createClient } = require('@supabase/supabase-js')

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
)

async function saveCards(events, groupId) {
  if (!events || events.length === 0) return

  for (const event of events) {
    // dedup — if same group + type + subject + date exists, update it
    const { error } = await supabase
      .from('event_cards')
      .upsert(
        {
          group_id: groupId,
          type: event.type,
          subject: event.subject,
          date: event.date,
          description: event.description,
          is_tentative: event.is_tentative || false,
          new_time: event.new_time || null,
          syllabus: event.syllabus || null,
          source_msg: event.source_msg || null,
          sent_by: event.sent_by || null,
          confidence: event.confidence || 'high',
          generated_at: new Date().toISOString()
        },
        {
          onConflict: 'group_id, type, subject, date'
        }
      )

    if (error) {
      console.error('Supabase upsert error:', error.message)
    }
  }

  console.log(`✅ Saved ${events.length} events to Supabase`)
}

async function getCards(groupId) {
  const { data, error } = await supabase
    .from('event_cards')
    .select('*')
    .eq('group_id', groupId)
    .order('date', { ascending: true })

  if (error) {
    console.error('Supabase fetch error:', error.message)
    return []
  }

  return data
}
async function getLastProcessedTime(groupId) {
  const { data } = await supabase
    .from('last_processed')
    .select('last_timestamp')
    .eq('group_id', groupId)
    .single()

  return data?.last_timestamp || null
}

async function updateLastProcessedTime(groupId, timestamp) {
  await supabase
    .from('last_processed')
    .upsert(
      {
        group_id: groupId,
        last_timestamp: timestamp,
        updated_at: new Date().toISOString()
      },
      { onConflict: 'group_id' }
    )
}

module.exports = { saveCards, getCards, getLastProcessedTime, updateLastProcessedTime }