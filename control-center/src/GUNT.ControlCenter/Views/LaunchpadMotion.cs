using System;using System.Windows;using System.Windows.Controls;using System.Windows.Media.Animation;
namespace Gunt.ControlCenter.Views {
 public sealed partial class LaunchpadWindow {
  internal bool MotionEnabled {get{return config.Animations&&SystemParameters.ClientAreaAnimation;}}
  void OpeningMotion(){BeginAnimation(OpacityProperty,null);Opacity=1;if(MotionEnabled)BeginAnimation(OpacityProperty,new DoubleAnimation(.92,1,TimeSpan.FromMilliseconds(110)){FillBehavior=FillBehavior.Stop});}
  void IconHover(Image image){if(MotionEnabled)image.BeginAnimation(OpacityProperty,new DoubleAnimation(.86,1,TimeSpan.FromMilliseconds(90)){FillBehavior=FillBehavior.Stop});}
 }
}
