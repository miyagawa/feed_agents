# feed_agents

This program analyzes the access log for your RSS feed, and outputs an aggregated count of the subscribers. The subscriber count is based on a unique IP address for client-installed user agents, but also supports hosted user-agents if they report their subscribers count in their UA string.

Based on Marco Arment's [feed-subscribers.php](https://gist.github.com/marcoarment/5968198)

## Usage

```
> tail -10000 /path/to/access_log | ./feed_agents /rss > agents.json
```

The program takes an optional argument, which is a path to their feed URL. The default is `/` and it would match all requests.

This will emit a following JSON file in the standard output:

```
{
 agents: [
  {
   agent: "Apple Podcasts",
   subscribers: 12345,
  },
  {
   agent: "iTunes (OS X)",
   subscribers: 3456,
  },
  ...
 ],
 total: 23456
}
```

## License

MIT



