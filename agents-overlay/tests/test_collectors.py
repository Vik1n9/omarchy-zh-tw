#!/usr/bin/python3

import importlib.machinery
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(name: str, file_name: str):
  loader = importlib.machinery.SourceFileLoader(name, str(ROOT / "bin" / file_name))
  spec = importlib.util.spec_from_loader(name, loader)
  module = importlib.util.module_from_spec(spec)
  loader.exec_module(module)
  return module


grok = load("grok_collector", "grok-collector")
kimi = load("kimi_collector", "kimi-collector")


class CollectorTests(unittest.TestCase):
  def test_grok_maps_weekly_percentage(self):
    limits = grok.parse_limits({
      "creditUsagePercent": 42.5,
      "currentPeriod": {
        "type": "USAGE_PERIOD_TYPE_WEEKLY",
        "start": "2026-08-24T00:00:00Z",
        "end": "2026-08-31T00:00:00Z",
      },
    })
    self.assertEqual(limits[0]["title"], "每週")
    self.assertEqual(limits[0]["percent"], 0.425)
    self.assertEqual(limits[0]["resetsAt"], "2026-08-31T00:00:00Z")

  def test_kimi_maps_weekly_and_rolling_windows(self):
    result = kimi.parse_usage({
      "user": {"membership": {"level": "LEVEL_INTERMEDIATE"}},
      "usage": {"limit": "100", "remaining": "74", "resetTime": "2026-09-01T00:00:00Z"},
      "limits": [{
        "window": {"duration": 300, "timeUnit": "TIME_UNIT_MINUTE"},
        "detail": {"limit": 100, "used": 15, "resetTime": "2026-08-30T12:00:00Z"},
      }],
    })
    self.assertTrue(result["ready"])
    self.assertEqual(result["tierLabel"], "Intermediate")
    self.assertEqual([item["title"] for item in result["limits"]], ["工作階段", "每週"])
    self.assertEqual(result["limits"][0]["percent"], 0.15)
    self.assertEqual(result["limits"][1]["percent"], 0.26)

  def test_kimi_rejects_unknown_usage_shape(self):
    with self.assertRaises(ValueError):
      kimi.parse_usage({"usage": {"remaining": 10}})


if __name__ == "__main__":
  unittest.main()
