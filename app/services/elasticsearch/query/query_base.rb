# Rescoring queries with multi-type fields
#   https://tryolabs.com/blog/2015/03/04/optimizing-elasticsearch-rescoring-queries-with-multi-type-fields/
# Strategies and Techniques for Relevance
#   https://www.compose.com/articles/elasticsearch-query-time-strategies-and-techniques-for-relevance-part-ii/

# create and query sample index
# curl -XDELETE http://localhost:9200/test &> /dev/null
# curl -XPUT http://localhost:9200/test | jq
# curl -XPOST http://localhost:9200/test/test/1 -d{'"name1":"test","name2":"test"}'
# curl -XPOST http://localhost:9200/test/test/2 -d{'"name1":"test"}'

# curl -XGET http://localhost:9200/test/test/_search -d'{
#   "query": {
#     "bool":{
#       "should": [
#         { "match": { "name1": "test" } },
#         { "match": { "name2": "test" } }
#       ]
#     }
#   }
# }' | jq

# curl -XGET http://localhost:9200/test/test/_search -d'{
#   "query": {
#     "dis_max":{
#       "queries": [
#         { "match": { "name1": "test" } },
#         { "match": { "name2": "test" } }
#       ]
#     }
#   }
# }' | jq

class Elasticsearch::Query::QueryBase
  method_object %i[phrase! limit!]

  def call
    index_klass
      .query(query)
      .limit(@limit)
      .each_with_object({}) { |v, memo| memo[v.id.to_i] = v._data['_score'] }
  end

private

  def index_klass
    "#{self.class.name.split('::').last.pluralize}Index".constantize
  end

  # use dis_max intead of bool in order to get correct results scoring
  # bool gets score summed from all matches
  # dis_max gets score from best match
  def query
    # {
    #   bool: { should: name_fields_match }
    # }

    {
      dis_max: {
        queries: name_fields_match,
        tie_breaker: 0,
        boost: 1
      }
    }
  end

  def name_fields_match
    index_klass::NAME_FIELDS.flat_map { |field| field_query(field) }
  end

  def field_query field
    [
      { match: { "#{field}.original": { query: @phrase, boost: 400 } } },
      { match: { "#{field}.edge_phrase": { query: @phrase, boost: 50 } } },
      { match: { "#{field}.edge_word": { query: @phrase, boost: 20 } } },
      { match: { "#{field}.ngram": { query: @phrase } } }
    ]
  end

  # def cache_key
  #   [
  #     type,
  #     @phrase,
  #     @limit,
  #     Elasticsearch::Reindex.time(type).to_i
  #   ]
  # end
end
