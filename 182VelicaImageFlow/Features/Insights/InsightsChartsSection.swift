import Charts
import SwiftUI

struct InsightsChartsSection: View {
    @EnvironmentObject private var store: MoodSyncDataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            activityChart
            extraStats
        }
    }

    private var activityChart: some View {
        let data = store.activityCounts(lastDays: 7)
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Activity — 7 days")
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Actions", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(shortWeekday(date))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color("AppTextSecondary").opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .frame(height: 190)
        }
        .padding(16)
        .depthRaised(cornerRadius: 18)
    }

    private var extraStats: some View {
        HStack(spacing: 12) {
            MetricCell(
                value: store.mostUsedEmoji().map { "\($0.emoji)" } ?? "—",
                label: store.mostUsedEmoji().map { "Used \($0.count)×" } ?? "Top Emoji",
                icon: "face.smiling"
            )
            MetricCell(
                value: store.topDiscoverCollectionTitle() ?? "—",
                label: "Top Collection",
                icon: "photo.stack"
            )
        }
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct PopularTagsCloud: View {
    let tags: [(tag: String, count: Int)]
    @Binding var selectedTag: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Popular tags")
            if tags.isEmpty {
                Text("Add tags to entries and journals to see trends here.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.tag) { item in
                        Button {
                            FeedbackManager.tapLight()
                            selectedTag = selectedTag == item.tag ? nil : item.tag
                        } label: {
                            Text("\(TagNormalizer.display(item.tag)) · \(item.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selectedTag == item.tag ? Color("AppBackground") : Color("AppPrimary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    selectedTag == item.tag
                                        ? Color("AppPrimary")
                                        : Color("AppBackground").opacity(0.5)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .depthRaised(cornerRadius: 18)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
