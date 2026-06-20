import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/domain/tomato_ticker.dart';

void main() {
  group('TomatoTicker 状态流转与边界测试', () {
    test('初始状态校验', () {
      final ticker = TomatoTicker(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakInterval: 4,
      );
      expect(ticker.status, TomatoStatus.idle);
      expect(ticker.duration, 25 * 60);
      expect(ticker.isRunning, false);
      expect(ticker.isPaused, false);
    });

    test('手动调节快速切换时间段', () {
      final ticker = TomatoTicker();

      ticker.selectShortBreak();
      expect(ticker.status, TomatoStatus.shortBreak);
      expect(ticker.duration, 5 * 60);

      ticker.selectLongBreak();
      expect(ticker.status, TomatoStatus.longBreak);
      expect(ticker.duration, 15 * 60);

      ticker.selectFocus();
      expect(ticker.status, TomatoStatus.idle);
      expect(ticker.duration, 25 * 60);
    });

    test('状态控制流（启动、暂停、继续、滴答减少时间）', () {
      final ticker = TomatoTicker();

      ticker.start();
      expect(ticker.status, TomatoStatus.focus);
      expect(ticker.isRunning, true);
      expect(ticker.isPaused, false);

      ticker.pause();
      expect(ticker.isPaused, true);

      ticker.resume();
      expect(ticker.isPaused, false);

      ticker.tick(10);
      expect(ticker.duration, 25 * 60 - 10);
    });

    test(
      '使用自定义 TimeProvider 和 tick() 快速跑完 25分钟 专注，触发 FocusCompleteEvent 转换到短休状态',
      () async {
        DateTime mockTime = DateTime(2026, 6, 19, 10, 0, 0);

        // 创建 Ticker 并将 autoStartBreak 设为 false 以便断言当前状态
        final ticker = TomatoTicker(
          focusMinutes: 25,
          shortBreakMinutes: 5,
          autoStartBreak: false,
          currentTimeProvider: () => mockTime,
        );

        ticker.start();

        final List<TomatoEvent> receivedEvents = [];
        final subscription = ticker.eventStream.listen(receivedEvents.add);

        // 模拟时钟快进 25 分钟
        mockTime = mockTime.add(const Duration(minutes: 25));

        // 手动触发一次 tick，走完剩余 25 分钟的秒数
        ticker.tick(25 * 60);

        // 验证状态机已经自动流转为短休，并且已不再运行
        expect(ticker.status, TomatoStatus.shortBreak);
        expect(ticker.isRunning, false);
        expect(ticker.duration, 5 * 60);

        // 校验派发了专注完成事件
        final completeEvents = receivedEvents
            .whereType<TomatoFocusCompleteEvent>();
        expect(completeEvents.length, 1);

        final event = completeEvents.first;
        expect(event.durationMinutes, 25);
        expect(event.startTime, DateTime(2026, 6, 19, 10, 0, 0));
        expect(event.endTime, DateTime(2026, 6, 19, 10, 25, 0));

        await subscription.cancel();
      },
    );

    test('多次专注循环后自动流转为长休，并在长休结束后重置循环', () {
      final ticker = TomatoTicker(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakInterval: 2, // 设长休间隔为 2 次专注
        autoStartBreak: false,
        autoStartFocus: false,
      );

      // 第一轮专注
      ticker.start();
      ticker.tick(25 * 60);
      expect(ticker.status, TomatoStatus.shortBreak);
      expect(ticker.completedTomatoCount, 1);

      // 短休
      ticker.start();
      ticker.tick(5 * 60);
      expect(ticker.status, TomatoStatus.idle);

      // 第二轮专注
      ticker.start();
      ticker.tick(25 * 60);

      // 完成第 2 次专注后，应该自动流转到长休状态，并且重置 completedTomatoCount
      expect(ticker.status, TomatoStatus.longBreak);
      expect(ticker.completedTomatoCount, 0);
      expect(ticker.duration, 15 * 60);
    });

    test('中途放弃专注，触发 TomatoAbandonEvent', () async {
      DateTime mockTime = DateTime(2026, 6, 19, 10, 0, 0);
      final ticker = TomatoTicker(
        focusMinutes: 25,
        currentTimeProvider: () => mockTime,
      );

      ticker.start();

      final List<TomatoEvent> receivedEvents = [];
      final subscription = ticker.eventStream.listen(receivedEvents.add);

      // 专注进行了 10 分钟
      mockTime = mockTime.add(const Duration(minutes: 10));
      ticker.abandon();

      expect(ticker.status, TomatoStatus.idle);
      expect(ticker.isRunning, false);
      expect(ticker.startTime, null);

      // 验证收到了放弃事件，且时长计算准确
      final abandonEvents = receivedEvents.whereType<TomatoAbandonEvent>();
      expect(abandonEvents.length, 1);

      final event = abandonEvents.first;
      expect(event.durationMinutes, 10);
      expect(event.startTime, DateTime(2026, 6, 19, 10, 0, 0));
      expect(event.endTime, DateTime(2026, 6, 19, 10, 10, 0));

      await subscription.cancel();
    });
  });
}
